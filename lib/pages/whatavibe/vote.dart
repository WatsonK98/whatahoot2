
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';

///Created by Gustavo Rubio

class VotePage extends StatefulWidget {
  const VotePage({super.key});

  @override
  State<VotePage> createState() => _VotePageState();
}

class _VotePageState extends State<VotePage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Map<String, dynamic> captionsData;
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

    } else {}
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
      'gameStage': 3
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
    if (snapshot.value == 3) {
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

  ///Remove the captions to start fresh for the next image
  Future<void> _removeCaptions() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');

    DatabaseReference captionRef = FirebaseDatabase.instance.ref().child('$serverId/captions');
    captionRef.set({

    });
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

  ///Here we will send the caption to the server
  Future<void> _sendVote(String caption) async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');

    DatabaseReference captionsRef = FirebaseDatabase.instance.ref().child('$serverId/captions');
    final snapshot = await captionsRef.get();

    captionsData = snapshot.value as Map<String, dynamic>;

    captionsData.forEach((uid, captionData) {
      if (caption == captionData['caption']) {
        DatabaseReference voteRef = FirebaseDatabase.instance.ref().child('$serverId/captions/$uid/votes');
        voteRef.set(ServerValue.increment(1));
      }
    });
  }

  ///Tally the votes and add it to the players score
  Future<void> _tallyVotes() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');

    DatabaseReference captionsRef = FirebaseDatabase.instance.ref().child('$serverId/captions');
    DatabaseReference playersRef = FirebaseDatabase.instance.ref().child('$serverId/players');
    final snapshot = await captionsRef.get();

    captionsData = snapshot.value as Map<String, dynamic>;

    captionsData.forEach((uid, captionData) {
      int votes = captionData['votes'];

      if (playersRef.child(uid).key == uid) {
        playersRef.child(uid).set(ServerValue.increment(votes));
      }
    });
  }

  @override
  void initState () {
    super.initState();
    _getImage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Vote!"),
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
                    : const CircularProgressIndicator()
            ),
            const SizedBox(height: 16),

          ],
        ),
      ),
    );
  }
}