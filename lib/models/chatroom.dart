class Chatroom {
  final String name;
  final String lastMessage;
  final String time;
  final String imageUrl;
  final int unreadMessages;

  Chatroom({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.imageUrl,
    required this.unreadMessages,
  });

  factory Chatroom.fromJson(Map<String, dynamic> json) {
    return Chatroom(
      name: json['name'] ?? 'Unnamed',
      lastMessage: json['lastMessage'] ?? '',
      time: json['time'] ?? '',
      imageUrl: json['imageUrl'] ?? 'https://via.placeholder.com/50',
      unreadMessages: json['unreadMessages'] ?? 0,
    );
  }
}
