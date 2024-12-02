import 'package:cloud_firestore/cloud_firestore.dart';

class RandomChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addToQueue(String userId) async {
    await _firestore.collection('queue').doc(userId).set({
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<String?> waitForMatch(String userId) async* {
    await for (var snapshot in _firestore
        .collection('queue')
        .where('userId', isNotEqualTo: userId)
        .snapshots()) {
      if (snapshot.docs.isNotEmpty) {
        final otherUserId = snapshot.docs.first.id;
        
        // 두 사용자 ID를 이용해 기존 채팅방이 있는지 확인하고 가져오기
        final chatId = await _findOrCreateChatRoom(userId, otherUserId);
        yield chatId;
      } else {
        yield null;
      }
    }
  }

  Future<String> _findOrCreateChatRoom(String userId, String otherUserId) async {
    // 두 사용자가 이미 존재하는 채팅방이 있는지 확인
    final existingChat = await _firestore
        .collection('chats')
        .where('users', arrayContains: userId)
        .get();

    for (var doc in existingChat.docs) {
      final users = List<String>.from(doc['users']);
      if (users.contains(otherUserId)) {
        return doc.id; // 기존 채팅방 ID 반환
      }
    }

    // 기존 채팅방이 없다면 새로 생성
    var chatDoc = await _firestore.collection('chats').add({
      'users': [userId, otherUserId],
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 대기열에서 두 사용자 제거
    await _firestore.collection('queue').doc(userId).delete();
    await _firestore.collection('queue').doc(otherUserId).delete();

    return chatDoc.id;
  }
}
