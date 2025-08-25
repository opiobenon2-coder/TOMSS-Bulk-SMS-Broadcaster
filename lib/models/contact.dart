class Contact {
  final int? id;
  final String name;
  final String phone;
  final String groupName;
  final String? classLevel;
  final String? parentName;
  final String? studentName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Contact({
    this.id,
    required this.name,
    required this.phone,
    required this.groupName,
    this.classLevel,
    this.parentName,
    this.studentName,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'group_name': groupName,
      'class_level': classLevel,
      'parent_name': parentName,
      'student_name': studentName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      groupName: map['group_name'] ?? '',
      classLevel: map['class_level'],
      parentName: map['parent_name'],
      studentName: map['student_name'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Contact copyWith({
    int? id,
    String? name,
    String? phone,
    String? groupName,
    String? classLevel,
    String? parentName,
    String? studentName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      groupName: groupName ?? this.groupName,
      classLevel: classLevel ?? this.classLevel,
      parentName: parentName ?? this.parentName,
      studentName: studentName ?? this.studentName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Contact{id: $id, name: $name, phone: $phone, groupName: $groupName}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Contact &&
        other.id == id &&
        other.name == name &&
        other.phone == phone &&
        other.groupName == groupName;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        phone.hashCode ^
        groupName.hashCode;
  }

  // Validation methods
  bool get isValid {
    return name.isNotEmpty && 
           phone.isNotEmpty && 
           groupName.isNotEmpty &&
           isValidPhoneNumber;
  }

  bool get isValidPhoneNumber {
    // Uganda phone number validation
    final phoneRegex = RegExp(r'^(\+256|0)(7[0-9]{8}|3[0-9]{8})$');
    return phoneRegex.hasMatch(phone.replaceAll(' ', '').replaceAll('-', ''));
  }

  String get formattedPhone {
    String cleanPhone = phone.replaceAll(' ', '').replaceAll('-', '');
    
    // Convert to international format
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '+256${cleanPhone.substring(1)}';
    } else if (!cleanPhone.startsWith('+256')) {
      cleanPhone = '+256$cleanPhone';
    }
    
    return cleanPhone;
  }

  String get displayName {
    if (parentName != null && studentName != null) {
      return '$parentName (Parent of $studentName)';
    } else if (parentName != null) {
      return '$parentName (Parent)';
    } else {
      return name;
    }
  }
}