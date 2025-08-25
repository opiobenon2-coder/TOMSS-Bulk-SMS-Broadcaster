import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../models/message_log.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tomss_sms.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Contacts table
    await db.execute('''
      CREATE TABLE contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL UNIQUE,
        group_name TEXT NOT NULL,
        class_level TEXT,
        parent_name TEXT,
        student_name TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Messages table (for drafts and templates)
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        is_template INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Message logs table (for sent messages tracking)
    await db.execute('''
      CREATE TABLE message_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipient_name TEXT NOT NULL,
        recipient_phone TEXT NOT NULL,
        message_content TEXT NOT NULL,
        status TEXT NOT NULL,
        sent_at TEXT NOT NULL,
        delivered_at TEXT,
        error_message TEXT,
        retry_count INTEGER DEFAULT 0
      )
    ''');

    // Contact groups table
    await db.execute('''
      CREATE TABLE contact_groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Insert default groups
    await db.insert('contact_groups', {
      'name': 'Parents',
      'description': 'Parents and guardians',
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('contact_groups', {
      'name': 'Staff',
      'description': 'School staff members',
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('contact_groups', {
      'name': 'S.1',
      'description': 'Senior 1 students parents',
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('contact_groups', {
      'name': 'S.2',
      'description': 'Senior 2 students parents',
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('contact_groups', {
      'name': 'S.3',
      'description': 'Senior 3 students parents',
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('contact_groups', {
      'name': 'S.4',
      'description': 'Senior 4 students parents',
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('contact_groups', {
      'name': 'S.5',
      'description': 'Senior 5 students parents',
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('contact_groups', {
      'name': 'S.6',
      'description': 'Senior 6 students parents',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Contact operations
  Future<int> insertContact(Contact contact) async {
    final db = await instance.database;
    return await db.insert('contacts', contact.toMap());
  }

  Future<List<Contact>> getAllContacts() async {
    final db = await instance.database;
    final result = await db.query('contacts', orderBy: 'name ASC');
    return result.map((map) => Contact.fromMap(map)).toList();
  }

  Future<List<Contact>> getContactsByGroup(String groupName) async {
    final db = await instance.database;
    final result = await db.query(
      'contacts',
      where: 'group_name = ?',
      whereArgs: [groupName],
      orderBy: 'name ASC',
    );
    return result.map((map) => Contact.fromMap(map)).toList();
  }

  Future<int> updateContact(Contact contact) async {
    final db = await instance.database;
    return await db.update(
      'contacts',
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  Future<int> deleteContact(int id) async {
    final db = await instance.database;
    return await db.delete(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> bulkInsertContacts(List<Contact> contacts) async {
    final db = await instance.database;
    final batch = db.batch();
    
    for (final contact in contacts) {
      batch.insert('contacts', contact.toMap());
    }
    
    final results = await batch.commit();
    return results.length;
  }

  // Message operations
  Future<int> insertMessage(Message message) async {
    final db = await instance.database;
    return await db.insert('messages', message.toMap());
  }

  Future<List<Message>> getAllMessages() async {
    final db = await instance.database;
    final result = await db.query('messages', orderBy: 'created_at DESC');
    return result.map((map) => Message.fromMap(map)).toList();
  }

  Future<List<Message>> getTemplates() async {
    final db = await instance.database;
    final result = await db.query(
      'messages',
      where: 'is_template = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => Message.fromMap(map)).toList();
  }

  Future<int> updateMessage(Message message) async {
    final db = await instance.database;
    return await db.update(
      'messages',
      message.toMap(),
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  Future<int> deleteMessage(int id) async {
    final db = await instance.database;
    return await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Message log operations
  Future<int> insertMessageLog(MessageLog log) async {
    final db = await instance.database;
    return await db.insert('message_logs', log.toMap());
  }

  Future<List<MessageLog>> getAllMessageLogs() async {
    final db = await instance.database;
    final result = await db.query('message_logs', orderBy: 'sent_at DESC');
    return result.map((map) => MessageLog.fromMap(map)).toList();
  }

  Future<List<MessageLog>> getMessageLogsByStatus(String status) async {
    final db = await instance.database;
    final result = await db.query(
      'message_logs',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'sent_at DESC',
    );
    return result.map((map) => MessageLog.fromMap(map)).toList();
  }

  Future<int> updateMessageLog(MessageLog log) async {
    final db = await instance.database;
    return await db.update(
      'message_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  // Contact group operations
  Future<List<String>> getAllGroups() async {
    final db = await instance.database;
    final result = await db.query('contact_groups', orderBy: 'name ASC');
    return result.map((map) => map['name'] as String).toList();
  }

  Future<int> insertGroup(String name, String description) async {
    final db = await instance.database;
    return await db.insert('contact_groups', {
      'name': name,
      'description': description,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Statistics
  Future<Map<String, int>> getStatistics() async {
    final db = await instance.database;
    
    final totalContacts = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM contacts')
    ) ?? 0;
    
    final totalMessages = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM message_logs')
    ) ?? 0;
    
    final sentMessages = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM message_logs WHERE status = ?', ['sent'])
    ) ?? 0;
    
    final failedMessages = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM message_logs WHERE status = ?', ['failed'])
    ) ?? 0;
    
    final pendingMessages = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM message_logs WHERE status = ?', ['pending'])
    ) ?? 0;

    return {
      'totalContacts': totalContacts,
      'totalMessages': totalMessages,
      'sentMessages': sentMessages,
      'failedMessages': failedMessages,
      'pendingMessages': pendingMessages,
    };
  }

  // Search contacts
  Future<List<Contact>> searchContacts(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'contacts',
      where: 'name LIKE ? OR phone LIKE ? OR parent_name LIKE ? OR student_name LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return result.map((map) => Contact.fromMap(map)).toList();
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}