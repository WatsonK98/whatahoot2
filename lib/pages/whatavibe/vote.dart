import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whatahoot2/pages/whatavibe/win.dart';
import 'package:whatahoot2/pages/whatavibe/upload.dart';

///Created By Alexander Watson

class VotePage extends StatefulWidget {
  const VotePage({super.key});

  @override
  State<VotePage> createState() => _VotePageState();
}

class _VotePageState extends State<VotePage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Map<dynamic, dynamic> captionsData;
  late String? _imageUrl = null;
  late String? _title = '';
  late String? _artist = '';
  bool ready = false;

  ///Here we will get the image from storage and download it
  Future<void> _getImage() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');

    final storageRef = FirebaseStorage.instance.ref();
    final imageRef = storageRef.child('$serverId');
    final ListResult result = await imageRef.listAll();

    final Reference firstImage = result.items.first;
    _imageUrl = await firstImage.getDownloadURL();

    setState(() {});
    final imageName = firstImage.fullPath.toString().split('/').last;
    await prefs.setString('imageName', imageName);
  }

  Future<void> _getCaptions() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('serverId');
    String? imageName = prefs.getString('imageName');

    DatabaseReference captionsRef = FirebaseDatabase.instance.ref().child('$serverId/captions/$imageName');
    final title = await captionsRef.child('title').get();
    final artist = await captionsRef.child('artist').get();

    setState(() {
      _title = title.value.toString();
      _artist = artist.value.toString();
    });
  }

  Future<void> _voteCaption() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('serverId');
    String? imageName = prefs.getString('imageName');

    DatabaseReference captionsRef = FirebaseDatabase.instance.ref().child('$serverId/captions/$imageName/votes');
    await captionsRef.set({ServerValue.increment(1)});
    await _updatePlayerReady();
  }

  ///Update the players ready state
  Future<void> _updatePlayerReady() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');

    DatabaseReference playerRef = FirebaseDatabase.instance.ref().child('$serverId/players/ready');
    playerRef.set(ServerValue.increment(1));

    setState(() {
      ready = true;
    });
  }

  ///Make the player not ready again
  Future<void> _updatePlayerNotReady() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');

    DatabaseReference playerRef = FirebaseDatabase.instance.ref().child('$serverId/players/ready');
    playerRef.set(0);
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
      'gameStage': 1,
      'round': ServerValue.increment(1)
    });
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
      await _tallyVotes();
      await _checkRound();
      await _updatePlayerNotReady();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const UploadPage()));
    }
  }

  Future<void> _checkRound() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');
    int playerCount = prefs.getInt('playerCount') ?? 0;

    DatabaseReference roundRef = FirebaseDatabase.instance.ref().child('$serverId/round');
    final round = await roundRef.get();

    print(round.value);

    if (round.value == (playerCount*3)) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const WinPage()));
    }
  }

  ///If not the host then await for stage change
  Future<void> _listenGameStage() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');

    DatabaseReference serverRef = FirebaseDatabase.instance.ref().child('$serverId/gameStage');

    DataSnapshot snapshot = await serverRef.get();
    if (snapshot.value == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const UploadPage()));
    }
  }

  ///Tally the votes and add it to the players score
  Future<void> _tallyVotes() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');

    DatabaseReference captionsRef = FirebaseDatabase.instance.ref().child('$serverId/captions');
    DatabaseReference playersRef = FirebaseDatabase.instance.ref().child('$serverId/players');
    final snapshot = await captionsRef.get();
    captionsData = snapshot.value as Map<dynamic, dynamic>;

    captionsData.forEach((caption, captionData) {
      int votes = captionData['votes'];
      String uid = captionData['uid'];

      if (playersRef.child(uid).key == uid) {
        playersRef.child('$uid/score').set(ServerValue.increment(votes));
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _getImage();
    _getCaptions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Vote!'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey, Colors.black87]
          ),
        ),
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 24),
                Center(
                  child: _imageUrl != null
                    ? Image.network(
                    _imageUrl!,
                    width: 200,
                    height: 300,
                    fit: BoxFit.scaleDown,
                  )
                      : const CircularProgressIndicator(),
                ),
                const SizedBox(height: 16),
                Text(_title!, style: const TextStyle(color: Colors.white, fontSize: 24), textAlign: TextAlign.left),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.shuffle, color: Colors.white54, size: 48),
                    SizedBox(width: 8),
                    Icon(Icons.fast_rewind, color: Colors.white54, size: 48),
                    SizedBox(width: 8),
                    Icon(Icons.play_circle, color: Colors.white54, size: 48),
                    SizedBox(width: 8),
                    Icon(Icons.fast_forward, color: Colors.white54, size: 48),
                    SizedBox(width: 8),
                    Icon(Icons.replay, color: Colors.white54, size: 48),
                    SizedBox(width: 8)
                  ],
                ),
                const SizedBox(height: 16),
                Text('by $_artist', style: const TextStyle(color: Colors.white, fontSize: 24)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: () {
                        if (!ready) {
                          _voteCaption();
                        } else {
                          null;
                        }
                      },
                      child: const Text('Vote')
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (!ready) {
                          await _updatePlayerReady();
                          await _isHost();
                        } else {
                          await _isHost();
                        }
                      },
                      child: const Text('Continue'),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

}