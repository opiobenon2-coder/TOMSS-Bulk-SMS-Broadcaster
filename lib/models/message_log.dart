enum MessageStatus {
  pending,
  sent,
  delivered,
  failed,
  cancelled,
}

class MessageLog {
  final int? id;
  final String recipientName;
  final String recipientPhone;
  final String messageContent;
  final MessageStatus status;
  final DateTime sentAt;
  final DateTime? deliveredAt;
  final String? errorMessage;
  final int retryCount;

  MessageLog({
    this.id,
    required this.recipientName,
    required this.recipientPhone,
    required this.messageContent,
    required this.status,
    required this.sentAt,
    this.deliveredAt,
    this.errorMessage,
    this.retryCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'message_content': messageContent,
      'status': status.name,
      'sent_at': sentAt.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'error_message': errorMessage,
      'retry_count': retryCount,
    };
  }

  factory MessageLog.fromMap(Map<String, dynamic> map) {
    return MessageLog(
      id: map['id']?.toInt(),
      recipientName: map['recipient_name'] ?? '',
      recipientPhone: map['recipient_phone'] ?? '',
      messageContent: map['message_content'] ?? '',
      status: MessageStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MessageStatus.pending,
      ),
      sentAt: DateTime.parse(map['sent_at']),
      deliveredAt: map['delivered_at'] != null 
        ? DateTime.parse(map['delivered_at']) 
        : null,
      errorMessage: map['error_message'],
      retryCount: map['retry_count'] ?? 0,
    );
  }

  MessageLog copyWith({
    int? id,
    String? recipientName,
    String? recipientPhone,
    String? messageContent,
    MessageStatus? status,
    DateTime? sentAt,
    DateTime? deliveredAt,
    String? errorMessage,
    int? retryCount,
  }) {
    return MessageLog(
      id: id ?? this.id,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      messageContent: messageContent ?? this.messageContent,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  @override
  String toString() {
    return 'MessageLog{id: $id, recipient: $recipientName, status: $status}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageLog &&
        other.id == id &&
        other.recipientName == recipientName &&
        other.recipientPhone == recipientPhone &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        recipientName.hashCode ^
        recipientPhone.hashCode ^
        status.hashCode;
  }

  // Utility methods
  bool get isSuccessful {
    return status == MessageStatus.sent || status == MessageStatus.delivered;
  }

  bool get isFailed {
    return status == MessageStatus.failed || status == MessageStatus.cancelled;
  }

  bool get isPending {
    return status == MessageStatus.pending;
  }

  bool get canRetry {
    return isFailed && retryCount < 3;
  }

  String get statusDisplayName {
    switch (status) {
      case MessageStatus.pending:
        return 'Pending';
      case MessageStatus.sent:
        return 'Sent';
      case MessageStatus.delivered:
        return 'Delivered';
      case MessageStatus.failed:
        return 'Failed';
      case MessageStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get statusIcon {
    switch (status) {
      case MessageStatus.pending:
        return '⏳';
      case MessageStatus.sent:
        return '✅';
      case MessageStatus.delivered:
        return '📱';
      case MessageStatus.failed:
        return '❌';
      case MessageStatus.cancelled:
        return '🚫';
    }
  }

  Duration? get deliveryTime {
    if (deliveredAt != null) {
      return deliveredAt!.difference(sentAt);
    }
    return null;
  }

  String get formattedSentTime {
    final now = DateTime.now();
    final difference = now.difference(sentAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${sentAt.day}/${sentAt.month}/${sentAt.year}';
    }
  }

  String get messagePreview {
    if (messageContent.length <= 50) return messageContent;
    return '${messageContent.substring(0, 47)}...';
  }
}