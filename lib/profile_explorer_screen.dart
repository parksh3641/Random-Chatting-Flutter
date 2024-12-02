import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProfileExplorerScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('프로필 탐색')),
      body: StreamBuilder(
        stream: _firestore.collection('profiles').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return ListTile(
                title: Text(doc['name']),
                subtitle: Text('나이: ${doc['age']}'),
                trailing: ElevatedButton(
                  onPressed: () => _matchUser(doc.id),
                  child: Text('좋아요'),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Future<void> _matchUser(String userId) async {
    // 매칭 처리 로직을 여기에 추가
  }
}
