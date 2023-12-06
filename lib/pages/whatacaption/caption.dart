import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:whatahoot2/pages/whatacaption/vote.dart';
import 'package:whatahoot2/pages/whatacaption/win.dart';


///Created By Nathanael Perez

class CaptionPage extends StatefulWidget {
  const CaptionPage({super.key});

  ///Initialize the caption page state
  @override
  State<CaptionPage> createState() => _CaptionPageState();
}

///This is the caption page state
class _CaptionPageState extends State<CaptionPage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final TextEditingController _commentController = TextEditingController();
  late String? _imageUrl = null;
  late bool ready = false;

  ///Check if the last page was vote then remove captions and the image
  Future<void> _hostOps() async {
    SharedPreferences prefs = await _prefs;

    //Load appropriate data
    String? serverId = prefs.getString('joinCode');
    String? userId = prefs.getString('userId');

    //Make a database pointer
    DatabaseReference serverRef = FirebaseDatabase.instance.ref().child(serverId!);

    //Get the child and make a snapshot
    final hostRef = serverRef.child('players/$userId/host');
    final snapshot = await hostRef.get();

    //Check the game stage
    final gameStageRef = serverRef.child('gameStage');
    final stageFour = await gameStageRef.get();
    if (stageFour.value == 4) {
      if (snapshot.value == true) {
        //remove image and associated captions
        await _removeImage();
        await _removeCaptions();
      }
    }
  }

  ///Remove the image from storage
  Future<void> _removeImage() async {
    SharedPreferences prefs = await _prefs;

    //Load data
    String? serverId = prefs.getString('joinCode');

    //Create a storage reference
    final storageRef = FirebaseStorage.instance.ref();
    var imageRef = storageRef.child('$serverId');
    //List the storage items
    final ListResult result = await imageRef.listAll();

    //check if not empty
    if (result.items.isNotEmpty) {
      //get the first image and keep the name
      final Reference firstImage = result.items.first;
      String imageName = firstImage.name;

      //Delete the image in the storage
      imageRef = storageRef.child('$serverId/$imageName');
      await imageRef.delete();
    }
  }

  ///Remove the captions to start fresh for the next image
  Future<void> _removeCaptions() async {
    SharedPreferences prefs = await _prefs;

    //Load data
    String? serverId = prefs.getString('joinCode');

    //Create the database reference
    DatabaseReference captionRef = FirebaseDatabase.instance.ref().child('$serverId/captions');
    //Set the captions reference as blank
    captionRef.set({});
  }

  ///Here we will get the image from storage and download it
  Future<void> _getImage() async {
    SharedPreferences prefs = await _prefs;

    //Load data
    String? serverId = prefs.getString('joinCode');

    //Create a Storage reference
    final storageRef = FirebaseStorage.instance.ref();
    final imageRef = storageRef.child('$serverId');
    //List the items
    final ListResult result = await imageRef.listAll();

    //Check if it's not empty
    if (result.items.isNotEmpty) {
      //Get the first image and change to the URL
      final Reference firstImage = result.items.first;
      _imageUrl = await firstImage.getDownloadURL();

      setState(() {});
      //Otherwise: winpage
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const WinPage()));
    }
  }

  ///Here we will send the caption to the server
  Future<void> _sendCaption() async {
    SharedPreferences prefs = await _prefs;

    //Load data
    String? serverId = prefs.getString('joinCode');
    String? uid = prefs.getString('userId');

    //Create a Database reference
    DatabaseReference commentRef = FirebaseDatabase.instance.ref().child('$serverId/captions/$uid');
    //Set the comment with the controller
    commentRef.set({
      'caption': _commentController.text,
      'votes': 0
    });
    //Update the player ready state
    await _updatePlayerReady();
    ready = true;
  }

  ///Update the players ready state
  Future<void> _updatePlayerReady() async {
    SharedPreferences prefs = await _prefs;

    //Load Data
    String? serverId = prefs.getString('joinCode');

    //Load the server ready counter and increment
    DatabaseReference playerRef = FirebaseDatabase.instance.ref().child('$serverId/players/ready');
    playerRef.set(ServerValue.increment(1));
  }

  ///Check if the player is the game host
  Future<void> _isHost() async {
    SharedPreferences prefs = await _prefs;

    //Load data
    String? serverId = prefs.getString('joinCode');
    String? userId = prefs.getString('userId');

    //Load host reference
    DatabaseReference hostRef = FirebaseDatabase.instance.ref().child('$serverId/players/$userId/host');
    final snapshot = await hostRef.get();

    //If the host then wait for players
    //If not the host then check the state
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

    //Create stage reference
    DatabaseReference serverRef = FirebaseDatabase.instance.ref().child('$serverId');
    await serverRef.update({
      'gameStage': 3
    });
  }

  ///Make the player not ready again
  Future<void> _updatePlayerNotReady() async {
    SharedPreferences prefs = await _prefs;

    //load data
    String? serverId = prefs.getString('joinCode');

    //Create ready ref and reset to 0
    DatabaseReference playerRef = FirebaseDatabase.instance.ref().child('$serverId/players/ready');
    playerRef.set(0);
  }

  ///Await for players ready
  Future<void> _awaitPlayersReady() async {
    SharedPreferences prefs = await _prefs;

    //load data
    String? serverId = prefs.getString('joinCode');
    int playerCount = prefs.getInt('playerCount') ?? 0;

    //create ready ref
    DatabaseReference readyRef = FirebaseDatabase.instance.ref().child('$serverId/players/ready');
    final snapshot = await readyRef.get();

    //Check if the players are ready and move on
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

    //load data
    String? serverId = prefs.getString('joinCode');

    //create a gamestage reference
    DatabaseReference serverRef = FirebaseDatabase.instance.ref().child('$serverId/gameStage');

    //move to the vote page
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