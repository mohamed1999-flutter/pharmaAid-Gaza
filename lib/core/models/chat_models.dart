import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String id;
  final String userId;
  final String userName;
  final String? userImageUrl;
  final String pharmacyId;
  final String pharmacyName;
  final String? pharmacyImageUrl;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int userUnreadCount;
  final int pharmacyUnreadCount;
  final DateTime createdAt;

  ChatRoomModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userImageUrl,
    required this.pharmacyId,
    required this.pharmacyName,
    this.pharmacyImageUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.userUnreadCount,
    required this.pharmacyUnreadCount,
    required this.createdAt,
  });

  factory ChatRoomModel.fromMap(String id, Map<String, dynamic> map) {
    try {
      return ChatRoomModel(
        id: id,
        userId: map['userId'] ?? '',
        userName: map['userName'] ?? '',
        userImageUrl: map['userImageUrl'],
        pharmacyId: map['pharmacyId'] ?? '',
        pharmacyName: map['pharmacyName'] ?? '',
        pharmacyImageUrl: map['pharmacyImageUrl'],
        lastMessage: map['lastMessage'] ?? '',
        lastMessageTime:
            (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
        userUnreadCount: (map['userUnreadCount'] ?? 0) as int,
        pharmacyUnreadCount: (map['pharmacyUnreadCount'] ?? 0) as int,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      print('Error parsing ChatRoomModel for doc $id: $e');
      // Return a minimal model to avoid crashing the whole list
      return ChatRoomModel(
        id: id,
        userId: '',
        userName: 'Error loading chat',
        pharmacyId: '',
        pharmacyName: 'Error loading chat',
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        userUnreadCount: 0,
        pharmacyUnreadCount: 0,
        createdAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userImageUrl': userImageUrl,
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'pharmacyImageUrl': pharmacyImageUrl,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'userUnreadCount': userUnreadCount,
      'pharmacyUnreadCount': pharmacyUnreadCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class ChatMessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    required this.isRead,
  });

  factory ChatMessageModel.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }
}
