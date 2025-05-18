class DatabaseConstants {
  static const String databaseName = 'easyread.db';
  static const int databaseVersion = 1;
  
  // Table names
  static const String tableChats = 'chats';
  
  // Common column names
  static const String columnId = 'id';
  static const String columnUserMessage = 'userMessage';
  static const String columnBotResponse = 'botResponse';
  static const String columnTag = 'tag';
  static const String columnTimestamp = 'timestamp';
  
  // Create table statement
  static const String createChatsTable = '''
    CREATE TABLE $tableChats(
      $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnUserMessage TEXT NOT NULL,
      $columnBotResponse TEXT NOT NULL,
      $columnTag TEXT NOT NULL,
      $columnTimestamp TEXT NOT NULL
    )
  ''';
}