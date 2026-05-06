import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class VoiceMessageService {
  static Future<void> sendVoiceMessage({
    required String chatId,
    required File audioFile,
    required int durationSeconds,
  }) async {
    final user = FirebaseAuth.instance.currentUser!;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${user.uid}.m4a';
    final storageRef = FirebaseStorage.instance
        .ref('audio/voiceMessages/$chatId/$fileName');

    // Single upload — no loops
    await storageRef.putFile(
      audioFile,
      SettableMetadata(contentType: 'audio/m4a'),
    );
    final audioUrl = await storageRef.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'type': 'voice',
      'mediaUrl': audioUrl,
      'duration': durationSeconds,
      'content': '',
      'senderId': user.uid,
      'sentAt': FieldValue.serverTimestamp(),
      'readBy': [user.uid],
    });
  }
}