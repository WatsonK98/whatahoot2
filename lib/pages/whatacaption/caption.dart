import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:whatahoot2/pages/whatacaption/vote.dart';
import 'package:whatahoot2/pages/whatacaption/win.dart';


///Created By Nathanael Perez

class CaptionPage extends StatefulWidget {
  const CaptionPage({super.key});

  @override
  State<CaptionPage> createState() => _CaptionPageState();
}

class _CaptionPageState extends State<CaptionPage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final TextEditingController _commentController = TextEditingController();
  late String? _imageUrl;
  late bool gameReady = false;
  late bool ready = false;

  ///Here we will get the image from storage and download it
  Future<void> _getImage() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');

    final storageRef = FirebaseStorage.instance.ref();
    final imageRef = storageRef.child('$serverId');
    final ListResult result = await imageRef.listAll();

    if (result.items.isNotEmpty) {
      final Reference firstImage = result.items.first;
      _imageUrl = await firstImage.getDownloadURL();

      setState(() {});

    } else {
      Navigator.push(context,
        MaterialPageRoute(builder: (context) => const WinPage()));
    }
  }

  ///Here we will send the caption to the server
  Future<void> _sendCaption() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');
    String? uid = prefs.getString('userId');

    DatabaseReference commentRef = FirebaseDatabase.instance.ref().child('$serverId/captions/$uid');
    commentRef.set({
      'caption': _commentController.text,
      'votes': 0
    });
  }

  ///Update the players ready state
  Future<void> _updatePlayerReady() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');
    String? uid = prefs.getString('userId');

    DatabaseReference playerRef = FirebaseDatabase.instance.ref().child('$serverId/players/$uid');
    playerRef.update({
      'ready': true
    });
  }

  ///Check if the player is the game host
  Future<void> _isHost() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');
    String? userId = prefs.getString('userId');

    DatabaseReference hostRef = FirebaseDatabase.instance.ref().child('$serverId/players/$userId/host');
    final snapshot = await hostRef.get();

    if (snapshot.value == true) {
      await _updateGameStage();
      await _awaitPlayersReady();
    } else {
      await _listenGameStage();
    }
  }

  ///If the host then update the game state
  Future<void> _updateGameStage() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');

    DatabaseReference serverRef = FirebaseDatabase.instance.ref().child('$serverId');
    await serverRef.update({
      'gameStage': 2
    });
  }

  ///Make the player not ready again
  Future<void> _updatePlayerNotReady() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');
    String? uid = prefs.getString('userId');

    DatabaseReference playerRef = FirebaseDatabase.instance.ref().child('$serverId/players/$uid');
    playerRef.update({
      'ready': false
    });
  }

  ///Await for players ready
  Future<void> _awaitPlayersReady() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');
    int playerCount = prefs.getInt('playerCount') ?? 0;
    int readyCount = 1;

    DatabaseReference serverRef = FirebaseDatabase.instance.ref().child('$serverId/players');
    serverRef.onChildChanged.listen((event) {
      readyCount++;
      if (readyCount == playerCount) {
        setState(() {
          ready = true;
        });
      }
    });
  }

  ///If not the host then await for stage change
  Future<void> _listenGameStage() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');

    DatabaseReference serverRef = FirebaseDatabase.instance.ref().child('$serverId/gameStage');

    DataSnapshot snapshot = await serverRef.get();
    if (snapshot.value == 2) {
      setState(() {
        gameReady = true;
      });
    } else {
      serverRef.onChildChanged.listen((event) async {
        setState(() {
          gameReady = true;
        });
      });
    }
  }

  @override
  void initState () {
    super.initState();
    _getImage();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Caption!"),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 16),
            Center(
              child: _imageUrl != null
                  ? Image.network(
                _imageUrl!,
                width: 300,
                height: 300,
                fit: BoxFit.scaleDown,
              )
                  : const CircularProgressIndicator(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 300,
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter Caption',
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (_commentController.text.isNotEmpty) {
                  await _sendCaption();
                  await _updatePlayerReady();
                  await _isHost();

                  if (ready || gameReady) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const VotePage()));
                  }
                }
              },
              child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _imageFile {
}