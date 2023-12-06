import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

///Created By Alexander Watson

class VotePage extends StatefulWidget {
  const VotePage({super.key});

  @override
  State<VotePage> createState() => _VotePageState();
}

class _VotePageState extends State<VotePage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late String? _imageUrl = null;

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
  }

  ///Update the players ready state
  Future<void> _updatePlayerReady() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');

    DatabaseReference playerRef = FirebaseDatabase.instance.ref().child('$serverId/players/ready');
    playerRef.set(ServerValue.increment(1));
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
    final roundRef = await serverRef.child('round').get();
    await serverRef.update({
      'gameStage': 2,
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
      await _updatePlayerNotReady();
      //Navigate
    }
  }

  Future<void> _checkRound() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');

    DatabaseReference roundRef = FirebaseDatabase.instance.ref().child('$serverId/round');
    final round = await roundRef.get();
  }

  ///If not the host then await for stage change
  Future<void> _listenGameStage() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');

    DatabaseReference serverRef = FirebaseDatabase.instance.ref().child('$serverId/gameStage');

    DataSnapshot snapshot = await serverRef.get();
    if (snapshot.value == 2) {
      //Navigate
    }
  }

  @override
  void initState() {
    super.initState();
    _getImage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Vote!'),
      ),
    );
  }

}