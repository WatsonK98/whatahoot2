import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';

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
      print(playerData);
      final score = playerData['score'];
      if (score > highscore) {
        setState(() {
          winner = playerData['nickname'];
        });
      }
    });
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
        title: const Text("Vote!"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(winner, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
            const Text('Wins!', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('Back to Home'))
          ],
        ),
      ),
    );
  }
}