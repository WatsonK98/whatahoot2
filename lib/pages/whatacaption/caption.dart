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
  late String? _imageUrl = null;
  late bool ready = false;

  ///Check if the last page was vote then remove captions and the image
  Future<void> _hostOps() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');
    String? userId = prefs.getString('userId');

    DatabaseReference serverRef = FirebaseDatabase.instance.ref().child(serverId!);

    final hostRef = serverRef.child('players/$userId/host');
    final snapshot = await hostRef.get();

    final gameStageRef = serverRef.child('gameStage');
    final stageFour = await gameStageRef.get();
    if (stageFour.value == 4) {
      if (snapshot.value == true) {
        await _removeImage();
        await _removeCaptions();
      }
    }
  }

  ///Remove the image from storage
  Future<void> _removeImage() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');

    final storageRef = FirebaseStorage.instance.ref();
    var imageRef = storageRef.child('$serverId');
    final ListResult result = await imageRef.listAll();

    if (result.items.isNotEmpty) {
      final Reference firstImage = result.items.first;
      String imageName = firstImage.name;

      imageRef = storageRef.child('$serverId/$imageName');
      await imageRef.delete();
    }
  }

  ///Remove the captions to start fresh for the next image
  Future<void> _removeCaptions() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');

    DatabaseReference captionRef = FirebaseDatabase.instance.ref().child('$serverId/captions');
    captionRef.set({

    });
  }

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
      Navigator.of(context).push(
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
    await _updatePlayerReady();
    ready = true;
  }

  ///Update the players ready state
  Future<void> _updatePlayerReady() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');

    DatabaseReference playerRef = FirebaseDatabase.instance.ref().child('$serverId/players/ready');
    playerRef.set(ServerValue.increment(1));
  }

  ///Check if the player is the game host
  Future<void> _isHost() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');
    String? userId = prefs.getString('userId');

    DatabaseReference hostRef = FirebaseDatabase.instance.ref().child('$serverId/players/$userId/host');
    final snapshot = await hostRef.get();

    if (snapshot.value == true) {
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
      'gameStage': 3
    });
  }

  ///Make the player not ready again
  Future<void> _updatePlayerNotReady() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');

    DatabaseReference playerRef = FirebaseDatabase.instance.ref().child('$serverId/players/ready');
    playerRef.set(0);
  }

  ///Await for players ready
  Future<void> _awaitPlayersReady() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');
    int playerCount = prefs.getInt('playerCount') ?? 0;

    DatabaseReference readyRef = FirebaseDatabase.instance.ref().child('$serverId/players/ready');
    final snapshot = await readyRef.get();

    if (snapshot.value == playerCount) {
      await _updateGameStage();
      await _updatePlayerNotReady();
      Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const VotePage()));
    }
  }

  ///If not the host then await for stage change
  Future<void> _listenGameStage() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');

    DatabaseReference serverRef = FirebaseDatabase.instance.ref().child('$serverId/gameStage');

    DataSnapshot snapshot = await serverRef.get();
    if (snapshot.value == 3) {
      Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const VotePage()));
    }
  }

  @override
  void initState () {
    super.initState();
    _hostOps().then((_) {
      _getImage();
    });
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
                if (_commentController.text.isNotEmpty && !ready) {
                  await _sendCaption();
                  await _isHost();
                } else if (ready) {
                  await _isHost();
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