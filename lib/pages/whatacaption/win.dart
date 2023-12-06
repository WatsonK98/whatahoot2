import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WinPage extends StatefulWidget {
  const WinPage({super.key});


  @override
  State<WinPage> createState() => _WinPageState();
}

class _WinPageState extends State<WinPage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late String winner = '';

  ///Get the winner by comparing each players scores
  Future<void> _getWinner() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');

    DatabaseReference playersRef = FirebaseDatabase.instance.ref().child('$serverId/players');
    final snapshot = await playersRef.get();
    Map<dynamic, dynamic> playersData = snapshot.value as Map<dynamic, dynamic>;

    int highscore = 0;

    //compare players' scores
    playersData.forEach((uid, playerData) {
      final score = playerData['score'] as int;
      if (score > highscore) {
        setState(() {
          winner = playerData['nickname'];
        });
      } else if (score == highscore && score > 0) {
        setState(() {
          winner = 'Tie!';
        });
      }
    });
  }

  ///Delete the server since it is no longer needed
  Future<void> _isHost() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');
    String? userId = prefs.getString('userId');

    DatabaseReference hostRef = FirebaseDatabase.instance.ref().child('$serverId/players/$userId/host');
    final snapshot = await hostRef.get();

    if (snapshot.value == true) {
      await _deleteServer();
      await _deleteImages();
      await FirebaseAuth.instance.signOut();
    } else {
      await FirebaseAuth.instance.signOut();
    }
  }

  Future<void> _deleteServer() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');
    DatabaseReference serverRef = FirebaseDatabase.instance.ref().child(serverId!);
    await serverRef.remove();
  }

  Future<void> _deleteImages() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');

    await FirebaseStorage.instance.ref().child(serverId!).delete();
  }

  @override
  void initState() {
    super.initState();
    _getWinner();
  }

  @override
  Widget build (BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Winner!"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(winner, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: () async {
                await _isHost();
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('Back to Home'))
          ],
        ),
      ),
    );
  }
}