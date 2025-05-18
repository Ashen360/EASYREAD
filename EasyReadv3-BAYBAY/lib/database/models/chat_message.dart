class ChatMessage {
  final int? id;
  final String userMessage;
  final String botResponse;
  final String tag;
  final String timestamp;

  ChatMessage({
    this.id,
    required this.userMessage,
    required this.botResponse,
    required this.tag,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userMessage': userMessage,
      'botResponse': botResponse,
      'tag': tag,
      'timestamp': timestamp,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      userMessage: map['userMessage'],
      botResponse: map['botResponse'],
      tag: map['tag'],
      timestamp: map['timestamp'],
    );
  }
}