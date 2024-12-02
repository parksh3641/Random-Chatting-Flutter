import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'chat_screen.dart';
import 'random_chat_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AuthenticationScreen(),
    );
  }
}

class AuthenticationScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _signInAnonymously(BuildContext context) async {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainScreen(userId: userCredential.user!.uid),
        ),
      );
    } catch (e) {
      print("로그인 오류: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('랜덤 채팅 로그인')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _signInAnonymously(context),
          child: Text('로그인'),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final String userId;
  MainScreen({required this.userId});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool isLoading = false;
  StreamSubscription<String?>? _matchSubscription;
  Timer? _countdownTimer;
  int countdownSeconds = 10;

  Future<void> _startRandomChat() async {
    setState(() {
      isLoading = true;
    });

    // 사용자를 대기열에 추가
    await RandomChatService().addToQueue(widget.userId);

    // 대기 중 모달 창 띄우기
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // 타이머를 시작하고, 타이머가 실행될 때마다 setDialogState를 호출하여 UI 갱신
          if (_countdownTimer == null || !_countdownTimer!.isActive) {
            _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
              if (countdownSeconds > 0) {
                setState(() {
                  countdownSeconds--;
                });
                setDialogState(() {}); // 모달 창 UI 갱신
              } else {
                _cancelMatchmaking();
                if (Navigator.canPop(context)) {
                  Navigator.pop(context); // 대기 중 모달 창 닫기
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("매칭 시간이 초과되어 취소되었습니다.")),
                );
              }
            });
          }

          return AlertDialog(
            title: Text('상대방을 찾고 있습니다...'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text("대기 시간 : $countdownSeconds초"),
              ],
            ),
          );
        },
      ),
    );

    // 상대방을 기다리며 매칭을 확인
    _matchSubscription = RandomChatService().waitForMatch(widget.userId).listen((chatId) {
      if (chatId != null) {
        _cancelMatchmaking(); // 타이머와 매칭 구독 해제
        Navigator.pop(context); // 대기 중 모달 창 닫기
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatId: chatId, userId: widget.userId),
          ),
        );
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (countdownSeconds > 0) {
        setState(() {
          countdownSeconds--;
        });
      } else {
        _cancelMatchmaking();
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // 대기 중 모달 창 닫기
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("매칭 시간이 초과되어 취소되었습니다.")),
        );
      }
    });
  }

  void _cancelMatchmaking() {
    _matchSubscription?.cancel();
    _countdownTimer?.cancel();
    _countdownTimer = null; // 타이머 해제 후 null로 초기화하여 재실행 방지
    setState(() {
      isLoading = false;
      countdownSeconds = 10;
    });
  }

  @override
  void dispose() {
    _cancelMatchmaking(); // 모든 타이머와 스트림 구독 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('메인 화면')),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _startRandomChat,
                child: Text('랜덤 채팅 시작'),
              ),
      ),
    );
  }
}
