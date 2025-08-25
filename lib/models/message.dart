class Message {
  final int? id;
  final String title;
  final String content;
  final bool isTemplate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Message({
    this.id,
    required this.title,
    required this.content,
    this.isTemplate = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'is_template': isTemplate ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id']?.toInt(),
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      isTemplate: (map['is_template'] ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Message copyWith({
    int? id,
    String? title,
    String? content,
    bool? isTemplate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Message(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      isTemplate: isTemplate ?? this.isTemplate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Message{id: $id, title: $title, isTemplate: $isTemplate}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.isTemplate == isTemplate;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        content.hashCode ^
        isTemplate.hashCode;
  }

  // Validation and utility methods
  bool get isValid {
    return title.isNotEmpty && content.isNotEmpty;
  }

  int get characterCount {
    return content.length;
  }

  int get smsCount {
    // Standard SMS is 160 characters, but with Unicode it's 70
    const int smsLength = 160;
    const int unicodeSmsLength = 70;
    
    // Check if message contains Unicode characters
    bool hasUnicode = content.runes.any((rune) => rune > 127);
    int maxLength = hasUnicode ? unicodeSmsLength : smsLength;
    
    return (content.length / maxLength).ceil();
  }

  String get preview {
    if (content.length <= 50) return content;
    return '${content.substring(0, 47)}...';
  }

  // Message personalization
  String personalizeMessage(Map<String, String> variables) {
    String personalizedContent = content;
    
    variables.forEach((key, value) {
      personalizedContent = personalizedContent.replaceAll('[$key]', value);
    });
    
    return personalizedContent;
  }

  List<String> get mergeFields {
    final RegExp regex = RegExp(r'\[([^\]]+)\]');
    final matches = regex.allMatches(content);
    return matches.map((match) => match.group(1)!).toSet().toList();
  }

  bool get hasMergeFields {
    return mergeFields.isNotEmpty;
  }
}