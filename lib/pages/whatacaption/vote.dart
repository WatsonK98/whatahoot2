
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:whatahoot2/pages/whatacaption/caption.dart';
import 'package:whatahoot2/pages/whatacaption/win.dart';

///Created by Gustavo Rubio

class VotePage extends StatefulWidget {
  const VotePage({super.key});

  @override
  State<VotePage> createState() => _VotePageState();
}

class _VotePageState extends State<VotePage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final TextEditingController _textEditingController = TextEditingController();
  List<String> captions = [];
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

  ///Get the comments from the database
  Future<void> _getCaptions() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');

    DatabaseReference captionsRef = FirebaseDatabase.instance.ref().child('$serverId/captions');
    final snapshot = await captionsRef.get();
    print(snapshot.value);
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
  Future<void> _sendVote() async {

  }

  ///Tally the votes and add it to the players score
  Future<void> _tallyVotes() async {

  }

  @override
  void initState () {
    super.initState();
    _getImage();
    _getCaptions();
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
            ListView.builder(
                shrinkWrap: true,
                itemCount: captions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(captions[index]),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        await _sendVote();
                        await _updatePlayerReady();
                        await _isHost();

                        if (ready || gameReady) {
                          await _tallyVotes();
                          await _removeCaptions();
                          await _removeImage();
                          await _updatePlayerNotReady();

                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const CaptionPage()));
                        }
                      },
                      child: const Text('Vote'),
                    ),
                  );
                }
            ),
          ],
        ),
      ),
    );
  }
}