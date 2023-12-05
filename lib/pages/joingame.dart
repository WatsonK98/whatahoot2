import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'whatacaption/upload.dart';

class JoinGamePage extends StatefulWidget {
  const JoinGamePage({super.key});

  @override
  State<JoinGamePage> createState() => _JoinGamePageState();
}

class _JoinGamePageState extends State<JoinGamePage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final TextEditingController _joinCodeController = TextEditingController();
  final TextEditingController _nickNameController = TextEditingController();
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  ///Sign the user in
  Future<void> _signIn() async {
    SharedPreferences prefs = await _prefs;

    await prefs.setString('joinCode', _joinCodeController.text);

    //sign in anonymously so no email password combos
    await FirebaseAuth.instance.signInAnonymously();
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    String joinCode = _joinCodeController.text;

    //Initialize their spot in the database
    DatabaseReference playerRef = FirebaseDatabase.instance.ref().child('$joinCode/players/$uid');
    await playerRef.set({
      'nickname': _nickNameController.text,
      'host': false,
      'score': 0
    });
  }

  ///Wait for the game to start if joined game
  Future<void> _awaitGameStart() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');

    DatabaseReference gameStartRef = FirebaseDatabase.instance.ref().child('$serverId/gameStage');
    final snapshot = await gameStartRef.get();

    if (snapshot.value == 1) {
      Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const UploadPage()));
    }
    gameStartRef.onChildChanged.listen((event) {
      if (event.snapshot.value == 1) {
        setState(() {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const UploadPage()));
        });
      }
    });
  }

  ///Once the qr code is captured it'll stop the camera
  void _onQRViewCreated(QRViewController qrViewController) {
    controller = qrViewController;
    controller?.scannedDataStream.listen((scanData) {
      setState(() {
        _joinCodeController.text = scanData.code!;
      });
      controller?.stopCamera();
    });
  }

  @override
  void dispose() {
    _joinCodeController.dispose();
    _nickNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Join!'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 16),
              SizedBox(
                  height: 250,
                  width: 250,
                  child: QRView(
                    key: _qrKey,
                    onQRViewCreated: _onQRViewCreated,
                  )
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _joinCodeController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter join code'
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _nickNameController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter a nickname'
                  ),
                  maxLength: 8,
                ),
              ),
              ElevatedButton(
                  onPressed: () async {
                    if (_joinCodeController.text.isNotEmpty && _nickNameController.text.isNotEmpty) {
                      controller!.stopCamera();
                      await _signIn();
                      await _awaitGameStart();
                    }
                  },
                  child: const Text("Continue", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
              ),
            ],
          ),
        ),
      )
    );
  }
}