import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/contact.dart';
import '../models/message_log.dart';
import 'database_service.dart';
import 'dart:async';

class SMSService {
  static final SMSService instance = SMSService._init();
  final Telephony _telephony = Telephony.instance;
  final DatabaseService _db = DatabaseService.instance;
  
  // Queue management
  final List<SMSTask> _messageQueue = [];
  bool _isProcessing = false;
  Timer? _queueTimer;
  
  // Callbacks
  Function(String message)? onStatusUpdate;
  Function(int sent, int total)? onProgressUpdate;
  Function(String error)? onError;

  SMSService._init();

  // Initialize SMS service
  Future<bool> initialize() async {
    try {
      // Request SMS permissions
      final smsPermission = await Permission.sms.request();
      final phonePermission = await Permission.phone.request();
      
      if (smsPermission != PermissionStatus.granted || 
          phonePermission != PermissionStatus.granted) {
        onError?.call('SMS permissions not granted');
        return false;
      }

      // Check if SMS is available
      final bool? canSendSms = await _telephony.isSmsCapable;
      if (canSendSms != true) {
        onError?.call('Device cannot send SMS');
        return false;
      }

      onStatusUpdate?.call('SMS service initialized successfully');
      return true;
    } catch (e) {
      onError?.call('Failed to initialize SMS service: $e');
      return false;
    }
  }

  // Send single SMS
  Future<bool> sendSingleSMS({
    required String phoneNumber,
    required String message,
    String? recipientName,
  }) async {
    try {
      // Validate phone number
      if (!_isValidPhoneNumber(phoneNumber)) {
        throw Exception('Invalid phone number: $phoneNumber');
      }

      // Create message log entry
      final messageLog = MessageLog(
        recipientName: recipientName ?? 'Unknown',
        recipientPhone: phoneNumber,
        messageContent: message,
        status: MessageStatus.pending,
        sentAt: DateTime.now(),
      );

      final logId = await _db.insertMessageLog(messageLog);

      // Send SMS
      await _telephony.sendSms(
        to: phoneNumber,
        message: message,
        statusCallback: (SendStatus status) {
          _handleSMSStatus(logId, status);
        },
      );

      // Update log status
      await _db.updateMessageLog(
        messageLog.copyWith(
          id: logId,
          status: MessageStatus.sent,
        ),
      );

      onStatusUpdate?.call('SMS sent to $phoneNumber');
      return true;
    } catch (e) {
      onError?.call('Failed to send SMS to $phoneNumber: $e');
      
      // Update log with error
      final errorLog = MessageLog(
        recipientName: recipientName ?? 'Unknown',
        recipientPhone: phoneNumber,
        messageContent: message,
        status: MessageStatus.failed,
        sentAt: DateTime.now(),
        errorMessage: e.toString(),
      );
      await _db.insertMessageLog(errorLog);
      
      return false;
    }
  }

  // Send bulk SMS
  Future<void> sendBulkSMS({
    required List<Contact> contacts,
    required String message,
    int delayBetweenMessages = 2000, // 2 seconds delay
  }) async {
    if (contacts.isEmpty) {
      onError?.call('No contacts provided');
      return;
    }

    onStatusUpdate?.call('Starting bulk SMS to ${contacts.length} contacts');
    
    // Clear existing queue
    _messageQueue.clear();
    
    // Add messages to queue
    for (final contact in contacts) {
      final personalizedMessage = _personalizeMessage(message, contact);
      _messageQueue.add(SMSTask(
        contact: contact,
        message: personalizedMessage,
      ));
    }

    // Start processing queue
    await _processMessageQueue(delayBetweenMessages);
  }

  // Process message queue
  Future<void> _processMessageQueue(int delay) async {
    if (_isProcessing || _messageQueue.isEmpty) return;

    _isProcessing = true;
    int sent = 0;
    int total = _messageQueue.length;

    onProgressUpdate?.call(sent, total);

    for (int i = 0; i < _messageQueue.length; i++) {
      final task = _messageQueue[i];
      
      try {
        final success = await sendSingleSMS(
          phoneNumber: task.contact.formattedPhone,
          message: task.message,
          recipientName: task.contact.displayName,
        );

        if (success) {
          sent++;
          onProgressUpdate?.call(sent, total);
          onStatusUpdate?.call('Sent ${sent}/${total} messages');
        }

        // Delay between messages to avoid rate limiting
        if (i < _messageQueue.length - 1) {
          await Future.delayed(Duration(milliseconds: delay));
        }
      } catch (e) {
        onError?.call('Failed to send message to ${task.contact.name}: $e');
      }
    }

    _messageQueue.clear();
    _isProcessing = false;
    
    onStatusUpdate?.call('Bulk SMS completed. Sent $sent/$total messages');
  }

  // Handle SMS delivery status
  void _handleSMSStatus(int logId, SendStatus status) async {
    MessageStatus messageStatus;
    
    switch (status) {
      case SendStatus.SENT:
        messageStatus = MessageStatus.sent;
        break;
      case SendStatus.DELIVERED:
        messageStatus = MessageStatus.delivered;
        break;
      default:
        messageStatus = MessageStatus.failed;
    }

    // Update message log in database
    try {
      final logs = await _db.getAllMessageLogs();
      final log = logs.firstWhere((l) => l.id == logId);
      
      await _db.updateMessageLog(
        log.copyWith(
          status: messageStatus,
          deliveredAt: messageStatus == MessageStatus.delivered 
            ? DateTime.now() 
            : null,
        ),
      );
    } catch (e) {
      onError?.call('Failed to update message status: $e');
    }
  }

  // Personalize message with contact data
  String _personalizeMessage(String message, Contact contact) {
    String personalizedMessage = message;
    
    // Replace merge fields
    personalizedMessage = personalizedMessage.replaceAll('[Name]', contact.name);
    personalizedMessage = personalizedMessage.replaceAll('[Parent_Name]', contact.parentName ?? contact.name);
    personalizedMessage = personalizedMessage.replaceAll('[Student_Name]', contact.studentName ?? '');
    personalizedMessage = personalizedMessage.replaceAll('[Class]', contact.classLevel ?? '');
    personalizedMessage = personalizedMessage.replaceAll('[Phone]', contact.phone);
    
    // Add school signature
    if (!personalizedMessage.contains('TORORO MIXED S.S')) {
      personalizedMessage += '\n\n- TORORO MIXED S.S';
    }
    
    return personalizedMessage;
  }

  // Validate phone number
  bool _isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^(\+256|256|0)(7[0-9]{8}|3[0-9]{8})$');
    return phoneRegex.hasMatch(phone.replaceAll(' ', '').replaceAll('-', ''));
  }

  // Get SMS statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final stats = await _db.getStatistics();
    
    return {
      'totalMessages': stats['totalMessages'] ?? 0,
      'sentMessages': stats['sentMessages'] ?? 0,
      'failedMessages': stats['failedMessages'] ?? 0,
      'pendingMessages': stats['pendingMessages'] ?? 0,
      'successRate': stats['totalMessages'] > 0 
        ? ((stats['sentMessages'] ?? 0) / stats['totalMessages']! * 100).toStringAsFixed(1)
        : '0.0',
      'isProcessing': _isProcessing,
      'queueLength': _messageQueue.length,
    };
  }

  // Cancel bulk SMS
  void cancelBulkSMS() {
    _messageQueue.clear();
    _isProcessing = false;
    _queueTimer?.cancel();
    onStatusUpdate?.call('Bulk SMS cancelled');
  }

  // Retry failed messages
  Future<void> retryFailedMessages() async {
    final failedLogs = await _db.getMessageLogsByStatus('failed');
    final retryableLogs = failedLogs.where((log) => log.canRetry).toList();
    
    if (retryableLogs.isEmpty) {
      onStatusUpdate?.call('No messages to retry');
      return;
    }

    onStatusUpdate?.call('Retrying ${retryableLogs.length} failed messages');
    
    for (final log in retryableLogs) {
      try {
        final success = await sendSingleSMS(
          phoneNumber: log.recipientPhone,
          message: log.messageContent,
          recipientName: log.recipientName,
        );

        if (!success) {
          // Update retry count
          await _db.updateMessageLog(
            log.copyWith(retryCount: log.retryCount + 1),
          );
        }
      } catch (e) {
        onError?.call('Failed to retry message to ${log.recipientName}: $e');
      }
    }
  }

  // Check network status
  Future<bool> isNetworkAvailable() async {
    try {
      // This is a simplified check - in a real app you might want to use connectivity_plus
      return true; // Assume network is available for SMS
    } catch (e) {
      return false;
    }
  }

  // Dispose resources
  void dispose() {
    _queueTimer?.cancel();
    _messageQueue.clear();
    _isProcessing = false;
  }
}

// SMS Task class for queue management
class SMSTask {
  final Contact contact;
  final String message;
  final DateTime createdAt;

  SMSTask({
    required this.contact,
    required this.message,
  }) : createdAt = DateTime.now();

  @override
  String toString() {
    return 'SMSTask{contact: ${contact.name}, message: ${message.substring(0, 20)}...}';
  }
}