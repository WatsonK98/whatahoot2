import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:whatahoot2/pages/whatacaption/createqr.dart';
import 'package:whatahoot2/pages/whatavibe/createqr.dart';

///Created by Francisco Vazquez

class CreateGamePage extends StatefulWidget {
  const CreateGamePage({super.key});

  @override
  State<CreateGamePage> createState() => _CreateGamePageState();
}

class _CreateGamePageState extends State<CreateGamePage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final TextEditingController _nickNameController = TextEditingController();
  late String _joinCode = '';
  final Random _rnd = Random();
  final _chars = 'abcdefghijklmnopqrstuvwxyz1234567890';

  ///Random String generator for a specified length
  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  ///Create join code method gets the user nickname and generated join code.
  ///Saves the join code, and initializes the round to 0 to help with
  ///indexing of online resources
  Future<void> _createJoinCode() async {
    final SharedPreferences prefs = await _prefs;

    setState(() {
      _joinCode = getRandomString(5);
    });

    await prefs.setString('joinCode', _joinCode);
  }

  ///Create the server for the game state
  ///First signing in the player
  ///Then initializing the database space
  Future<void> _createServer() async {

    //Sign the player in to write to the database
    await FirebaseAuth.instance.signInAnonymously();

    //Initialize the database with the join code as the server ID
    DatabaseReference serverRef = FirebaseDatabase.instance.ref().child(_joinCode);
    await serverRef.set({
      'captions': {},
      'gameStage': 0,
      'players': {
        'ready': 1
      },
    });
  }

  ///Add the player
  ///First grab the controller text
  ///Second grab the uid
  ///Then set with host as true
  Future<void> _addPlayer() async {
    SharedPreferences prefs = await _prefs;
    final String nickname = _nickNameController.text;
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    await prefs.setString('userId', FirebaseAuth.instance.currentUser!.uid);

    //add the host params
    DatabaseReference playerRef = FirebaseDatabase.instance.ref().child('$_joinCode/players/$uid');
    await playerRef.set({
      'nickname': nickname,
      'host': true,
      'score': 0
    });
  }

  ///Dispose clears the controller and any other listeners except for
  ///shared preferences
  @override
  void dispose() {
    _nickNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Create!'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 200,
              child: TextField(
                controller: _nickNameController,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter a nickname'
                ),
                maxLength: 8,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: () async {
                  if (_nickNameController.text.isNotEmpty) {
                    await _createJoinCode();
                    await _createServer();
                    await _addPlayer();

                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const CreateCaptionQRPage()));
                  }
                },
                child: const Text('Whatacaption!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
            ),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: () async {
                  if (_nickNameController.text.isNotEmpty) {
                    await _createJoinCode();
                    await _createServer();
                    await _addPlayer();

                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const CreateVibeQRPage()));
                  }
                },
                child: const Text('Whatavibe!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
            ),
          ],
        ),
      )
    );
  }
}