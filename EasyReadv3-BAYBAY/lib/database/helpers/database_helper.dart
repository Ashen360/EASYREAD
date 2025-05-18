import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/chat_message.dart';
import '../constants/database_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, DatabaseConstants.databaseName);

    return await openDatabase(
      path,
      version: DatabaseConstants.databaseVersion,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute(DatabaseConstants.createChatsTable);
  }

  Future<void> insertChat(ChatMessage chat) async {
    final db = await database;
    
    // Get total number of chats
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseConstants.tableChats}')
    ) ?? 0;

    // If more than 10 chats, delete the oldest one
    if (count >= 10) {
      await db.delete(
        DatabaseConstants.tableChats,
        where: '${DatabaseConstants.columnId} IN (SELECT ${DatabaseConstants.columnId} FROM ${DatabaseConstants.tableChats} ORDER BY ${DatabaseConstants.columnTimestamp} ASC LIMIT 1)',
      );
    }

    await db.insert(DatabaseConstants.tableChats, chat.toMap());
  }

  Future<List<ChatMessage>> getRecentChats() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.tableChats,
      orderBy: '${DatabaseConstants.columnTimestamp} DESC',
      limit: 10,
    );

    return maps.map((map) => ChatMessage.fromMap(map)).toList();
  }

  Future<void> deleteAllChats() async {
    final db = await database;
    await db.delete(DatabaseConstants.tableChats);
  }

  Future<String> exportChatLogs() async {
    final chats = await getRecentChats();
    String export = 'EasyRead Chat Logs\n\n';

    for (var chat in chats) {
      export += '=== ${chat.tag} - ${chat.timestamp} ===\n';
      export += 'User: ${chat.userMessage}\n';
      export += 'AI: ${chat.botResponse}\n\n';
    }

    return export;
  }
}