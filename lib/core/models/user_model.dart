import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceInfo {
  final String id;
  final String name;
  final String type; // 'phone' | 'tablet' | 'laptop' | 'desktop'
  final DateTime lastActive;
  final bool isCurrentDevice;

  const DeviceInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.lastActive,
    this.isCurrentDevice = false,
  });

  factory DeviceInfo.fromMap(Map<String, dynamic> map) {
    return DeviceInfo(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unknown Device',
      type: map['type'] ?? 'phone',
      lastActive: (map['lastActive'] as Timestamp).toDate(),
      isCurrentDevice: map['isCurrentDevice'] ?? false,
    );
  }
}

class UserModel {
  final String uid;
  final String email;
  final String phoneNumber;
  final String displayName;
  final String username;
  final String photoUrl;
  final bool isOnline;
  final DateTime lastSeen;
  final DateTime createdAt;

  // ── New dynamic fields ──────────────────────────────
  final String bio;
  final String pinnedQuote;
  final List<String> mediaUrls; // ordered list of image/video URLs
  final int messageCount;
  final int groupCount;
  final int friendCount;

  const UserModel({
    required this.uid,
    required this.email,
    required this.phoneNumber,
    required this.displayName,
    required this.username,
    this.photoUrl = '',
    this.isOnline = false,
    required this.lastSeen,
    required this.createdAt,
    this.bio = '',
    this.pinnedQuote = '',
    this.mediaUrls = const [],
    this.messageCount = 0,
    this.groupCount = 0,
    this.friendCount = 0,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      displayName: map['displayName'] ?? '',
      username: map['username'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      isOnline: map['isOnline'] ?? false,
      lastSeen: (map['lastSeen'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      bio: map['bio'] ?? '',
      pinnedQuote: map['pinnedQuote'] ?? '',
      mediaUrls: List<String>.from(map['mediaUrls'] ?? []),
      messageCount: map['messageCount'] ?? 0,
      groupCount: map['groupCount'] ?? 0,
      friendCount: map['friendCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'username': username,
      'photoUrl': photoUrl,
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'createdAt': Timestamp.fromDate(createdAt),
      'bio': bio,
      'pinnedQuote': pinnedQuote,
      'mediaUrls': mediaUrls,
      'messageCount': messageCount,
      'groupCount': groupCount,
      'friendCount': friendCount,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? phoneNumber,
    String? displayName,
    String? username,
    String? photoUrl,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
    String? bio,
    String? pinnedQuote,
    List<String>? mediaUrls,
    int? messageCount,
    int? groupCount,
    int? friendCount,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      bio: bio ?? this.bio,
      pinnedQuote: pinnedQuote ?? this.pinnedQuote,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      messageCount: messageCount ?? this.messageCount,
      groupCount: groupCount ?? this.groupCount,
      friendCount: friendCount ?? this.friendCount,
    );
  }
}