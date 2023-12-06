import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:whatahoot2/pages/whatacaption/caption.dart';

///Created by Gustavo Rubio

class VotePage extends StatefulWidget {
  const VotePage({super.key});

  ///Create the state
  @override
  State<VotePage> createState() => _VotePageState();
}

class _VotePageState extends State<VotePage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  List<String> captions = [];
  late Map<dynamic, dynamic> captionsData;
  late String? _imageUrl = null;
  late bool gameReady = false;
  late bool ready = false;

  ///Here we will get the image from storage and download it
  Future<void> _getImage() async {
    SharedPreferences prefs = await _prefs;

    //load data
    String? serverId = prefs.getString('joinCode');

    //creata storage reference
    final storageRef = FirebaseStorage.instance.ref();
    final imageRef = storageRef.child('$serverId');
    final ListResult result = await imageRef.listAll();

    //get the download url
    if (result.items.isNotEmpty) {
      final Reference firstImage = result.items.first;
      _imageUrl = await firstImage.getDownloadURL();

      setState(() {});

    }
  }

  ///Get the comments from the database
  Future<void> _getCaptions() async {
    SharedPreferences prefs = await _prefs;

    //load data
    String? serverId = prefs.getString('joinCode');

    //make reference
    DatabaseReference captionsRef = FirebaseDatabase.instance.ref().child('$serverId/captions');
    final snapshot = await captionsRef.get();

    //Map the data
    captionsData = snapshot.value as Map<dynamic, dynamic>;

    //clear the captions data
    captions.clear();

    //list all the caption data
    captionsData.forEach((uid, captionData) {
      captions.add(captionData['caption']);
    });
  }

  ///Update the players ready state
  Future<void> _updatePlayerReady() async {
    SharedPreferences prefs = await _prefs;

    //load data
    String? serverId = prefs.getString('joinCode');

    //create reference to ready and increment
    DatabaseReference playerRef = FirebaseDatabase.instance.ref().child('$serverId/players/ready');
    playerRef.set(ServerValue.increment(1));
  }

  ///Check if the player is the game host
  Future<void> _isHost() async {
    SharedPreferences prefs = await _prefs;

    //load data
    String? serverId = prefs.getString('joinCode');
    String? userId = prefs.getString('userId');

    //create host reference
    DatabaseReference hostRef = FirebaseDatabase.instance.ref().child('$serverId/players/$userId/host');
    final snapshot = await hostRef.get();

    //check if host
    if (snapshot.value == true) {
      await _awaitPlayersReady();
    } else {
      await _listenGameStage();
    }
  }

  ///If the host then update the game state
  Future<void> _updateGameStage() async {
    SharedPreferences prefs = await _prefs;

    //load data
    String? serverId = prefs.getString('joinCode');

    //update game stage
    DatabaseReference serverRef = FirebaseDatabase.instance.ref().child('$serverId');
    await serverRef.update({
      'gameStage': 4
    });
  }

  ///Make the player not ready again
  Future<void> _updatePlayerNotReady() async {
    SharedPreferences prefs = await _prefs;

    //load data
    String? serverId = prefs.getString('joinCode');

    //set ready ref to 0
    DatabaseReference playerRef = FirebaseDatabase.instance.ref().child('$serverId/players/ready');
    playerRef.set(0);
  }

  ///Await for players ready
  Future<void> _awaitPlayersReady() async {
    SharedPreferences prefs = await _prefs;

    //load data
    String? serverId = prefs.getString('joinCode');
    int playerCount = prefs.getInt('playerCount') ?? 0;

    //get the ready info
    DatabaseReference readyRef = FirebaseDatabase.instance.ref().child('$serverId/players/ready');
    final snapshot = await readyRef.get();

    //if all players ready then move on
    if (snapshot.value == playerCount) {
      await _updateGameStage();
      await _tallyVotes();
      await _updatePlayerNotReady();
      Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const CaptionPage()));
    }
  }

  ///If not the host then await for stage change
  Future<void> _listenGameStage() async {
    SharedPreferences prefs = await _prefs;

    //load data
    String? serverId = prefs.getString('joinCode');

    //check stage
    DatabaseReference serverRef = FirebaseDatabase.instance.ref().child('$serverId/gameStage');

    DataSnapshot snapshot = await serverRef.get();

    //move on
    if (snapshot.value == 4) {
      Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const CaptionPage()));
    }
  }

  ///Here we will send the caption to the server
  Future<void> _sendVote(String caption) async {
    SharedPreferences prefs = await _prefs;

    //load data
    String? serverId = prefs.getString('joinCode');

    //get caption ref
    DatabaseReference captionsRef = FirebaseDatabase.instance.ref().child('$serverId/captions');
    final snapshot = await captionsRef.get();

    //Map the data
    captionsData = snapshot.value as Map<dynamic, dynamic>;

    //send vote to right caption
    captionsData.forEach((uid, captionData) {
      if (caption == captionData['caption']) {
        DatabaseReference voteRef = FirebaseDatabase.instance.ref().child('$serverId/captions/$uid/votes');
        voteRef.set(ServerValue.increment(1));
      }
    });
    await _updatePlayerReady();
    ready = true;
  }

  ///Tally the votes and add it to the players score
  Future<void> _tallyVotes() async {
    SharedPreferences prefs = await _prefs;

    //get data
    String? serverId = prefs.getString('joinCode');

    //create correct references
    DatabaseReference captionsRef = FirebaseDatabase.instance.ref().child('$serverId/captions');
    DatabaseReference playersRef = FirebaseDatabase.instance.ref().child('$serverId/players');
    final snapshot = await captionsRef.get();

    //map data
    captionsData = snapshot.value as Map<dynamic, dynamic>;

    //Apply the votes to the right player
    captionsData.forEach((uid, captionData) {
      int votes = captionData['votes'];

      if (playersRef.child(uid).key == uid) {
        playersRef.child('$uid/score').set(ServerValue.increment(votes));
      }
    });
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
                        if (!ready) {
                          await _sendVote(captions[index]);
                        } else {
                          null;
                        }
                      },
                      child: const Text('Vote'),
                    ),
                  );
                }
            ),
            ElevatedButton(
              onPressed: () async {
                await _isHost();
              },
              child: const Text('Continue!')
            ),
          ],
        ),
      ),
    );
  }
}