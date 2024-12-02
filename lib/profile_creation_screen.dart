import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileCreationScreen extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _createProfile() async {
    User? user = _auth.currentUser;
    await _firestore.collection('profiles').doc(user!.uid).set({
      'name': nameController.text,
      'age': int.parse(ageController.text),
      'interests': ['영화', '카페'], // 예시 데이터
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('프로필 생성')),
      body: Column(
        children: [
          TextField(controller: nameController, decoration: InputDecoration(labelText: '이름')),
          TextField(controller: ageController, decoration: InputDecoration(labelText: '나이'), keyboardType: TextInputType.number),
          ElevatedButton(onPressed: _createProfile, child: Text('프로필 생성'))
        ],
      ),
    );
  }
}
