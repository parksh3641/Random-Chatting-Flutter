import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String userId;

  ChatScreen({required this.chatId, required this.userId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _sendSystemMessage("${widget.userId} 님이 입장하였습니다.");
  }

  @override
  void dispose() {
    _sendSystemMessage("${widget.userId} 님이 방에서 나갔습니다.");
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendSystemMessage(String message) async {
    await _firestore.collection('chats').doc(widget.chatId).collection('messages').add({
      'text': message,
      'createdAt': FieldValue.serverTimestamp(),
      'isSystemMessage': true,
      'senderId': 'system', // 시스템 메시지는 senderId를 'system'으로 설정
    });
  }

  Future<void> _sendMessage() async {
    if (messageController.text.trim().isNotEmpty) {
      await _firestore.collection('chats').doc(widget.chatId).collection('messages').add({
        'senderId': widget.userId,
        'text': messageController.text,
        'createdAt': FieldValue.serverTimestamp(),
        'isSystemMessage': false,
      });
      messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('랜덤 채팅'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _firestore
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();

                // 새 메시지가 수신되면 자동 스크롤
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView(
                  controller: _scrollController,
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    bool isSystemMessage = data['isSystemMessage'] ?? false;
                    String senderId = data['senderId'] ?? '';

                    if (isSystemMessage) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            data['text'],
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      );
                    } else {
                      bool isCurrentUser = senderId == widget.userId;
                      return Align(
                        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                          padding: EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: isCurrentUser ? Colors.blue[100] : Colors.grey[300],
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                              bottomLeft: isCurrentUser ? Radius.circular(12) : Radius.circular(0),
                              bottomRight: isCurrentUser ? Radius.circular(0) : Radius.circular(12),
                            ),
                          ),
                          child: Text(
                            data['text'],
                            style: TextStyle(
                              color: Colors.black,
                            ),
                          ),
                        ),
                      );
                    }
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(hintText: '메시지를 입력하세요'),
                    onSubmitted: (value) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
