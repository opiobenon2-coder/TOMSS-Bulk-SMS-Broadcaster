import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';
import '../services/sms_service.dart';
import '../services/database_service.dart';
import '../models/contact.dart';
import '../models/message.dart';

class ComposeScreen extends StatefulWidget {
  const ComposeScreen({super.key});

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _messageController = TextEditingController();
  final _titleController = TextEditingController();
  final DatabaseService _db = DatabaseService.instance;
  final SMSService _smsService = SMSService.instance;

  List<String> _groups = [];
  String? _selectedGroup;
  List<Contact> _selectedContacts = [];
  List<Contact> _allContacts = [];
  List<Message> _templates = [];
  bool _isLoading = false;
  bool _isSending = false;
  int _sentCount = 0;
  int _totalCount = 0;
  DateTime? _scheduledTime;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupSMSCallbacks();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _setupSMSCallbacks() {
    _smsService.onStatusUpdate = (message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    };

    _smsService.onProgressUpdate = (sent, total) {
      if (mounted) {
        setState(() {
          _sentCount = sent;
          _totalCount = total;
        });
      }
    };

    _smsService.onError = (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    };
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final groups = await _db.getAllGroups();
      final contacts = await _db.getAllContacts();
      final templates = await _db.getTemplates();

      setState(() {
        _groups = groups;
        _allContacts = contacts;
        _templates = templates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load data: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadContactsForGroup(String? groupName) async {
    if (groupName == null) {
      setState(() {
        _selectedContacts = [];
      });
      return;
    }

    try {
      final contacts = await _db.getContactsByGroup(groupName);
      setState(() {
        _selectedContacts = contacts;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load contacts: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a message');
      return;
    }

    if (_selectedContacts.isEmpty) {
      _showErrorSnackBar('Please select contacts');
      return;
    }

    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    setState(() {
      _isSending = true;
      _sentCount = 0;
      _totalCount = _selectedContacts.length;
    });

    try {
      await _smsService.sendBulkSMS(
        contacts: _selectedContacts,
        message: _messageController.text.trim(),
        delayBetweenMessages: 2000, // 2 seconds delay
      );

      _showSuccessSnackBar('Bulk SMS completed successfully!');
      _clearForm();
    } catch (e) {
      _showErrorSnackBar('Failed to send messages: $e');
    } finally {
      setState(() {
        _isSending = false;
        _sentCount = 0;
        _totalCount = 0;
      });
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Send'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send message to ${_selectedContacts.length} contacts?'),
            const SizedBox(height: 8),
            Text(
              'Group: ${_selectedGroup ?? 'All'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _messageController.text.trim(),
                style: const TextStyle(fontSize: 12),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Send'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _clearForm() {
    _messageController.clear();
    _titleController.clear();
    setState(() {
      _selectedGroup = null;
      _selectedContacts = [];
      _scheduledTime = null;
    });
  }

  Future<void> _saveAsTemplate() async {
    if (_messageController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a message');
      return;
    }

    final title = await _showTitleDialog();
    if (title == null || title.trim().isEmpty) return;

    try {
      final template = Message(
        title: title.trim(),
        content: _messageController.text.trim(),
        isTemplate: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _db.insertMessage(template);
      await _loadData(); // Reload templates
      _showSuccessSnackBar('Template saved successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to save template: $e');
    }
  }

  Future<String?> _showTitleDialog() async {
    final controller = TextEditingController();
    
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Template'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Template Title',
            hintText: 'Enter template name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _loadTemplate(Message template) {
    setState(() {
      _messageController.text = template.content;
    });
    _showSuccessSnackBar('Template loaded: ${template.title}');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Message Templates
          if (_templates.isNotEmpty) _buildTemplatesSection(),
          
          const SizedBox(height: 16),
          
          // Group Selection
          _buildGroupSelection(),
          
          const SizedBox(height: 16),
          
          // Contact Count
          _buildContactCount(),
          
          const SizedBox(height: 16),
          
          // Message Composition
          _buildMessageComposer(),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          _buildActionButtons(),
          
          // Progress Indicator
          if (_isSending) _buildProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildTemplatesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Message Templates',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _templates.length,
                itemBuilder: (context, index) {
                  final template = _templates[index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 8),
                    child: Card(
                      elevation: 2,
                      child: InkWell(
                        onTap: () => _loadTemplate(template),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                template.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Expanded(
                                child: Text(
                                  template.preview,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Recipients',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedGroup,
              decoration: const InputDecoration(
                labelText: 'Contact Group',
                prefixIcon: Icon(Icons.group),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Select Group'),
                ),
                ..._groups.map((group) => DropdownMenuItem<String>(
                  value: group,
                  child: Text(group),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGroup = value;
                });
                _loadContactsForGroup(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCount() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.people,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Recipients: ${_selectedContacts.length}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Compose Message',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _saveAsTemplate,
                  icon: const Icon(Icons.save, size: 16),
                  label: const Text('Save Template'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 6,
              maxLength: 1000,
              decoration: const InputDecoration(
                hintText: 'Type your message here...\n\nAvailable merge fields:\n[Name] - Contact name\n[Parent_Name] - Parent name\n[Student_Name] - Student name\n[Class] - Class level',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Characters: ${_messageController.text.length}/1000',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                if (_messageController.text.isNotEmpty)
                  Text(
                    'SMS Count: ${Message(title: '', content: _messageController.text, createdAt: DateTime.now(), updatedAt: DateTime.now()).smsCount}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isSending || _selectedContacts.isEmpty || _messageController.text.trim().isEmpty
              ? null
              : _sendMessage,
            icon: _isSending 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.send),
            label: Text(_isSending ? 'Sending...' : 'Send Now'),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _clearForm,
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSending ? _smsService.cancelBulkSMS : null,
                icon: const Icon(Icons.stop),
                label: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.send, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Sending Messages: $_sentCount/$_totalCount',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _totalCount > 0 ? _sentCount / _totalCount : 0,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }
}