import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:whatahoot2/pages/whatacaption/createqr.dart';

class CreateGamePage extends StatefulWidget {
  const CreateGamePage({super.key});

  @override
  State<CreateGamePage> createState() => _CreateGamePageState();
}

class _CreateGamePageState extends State<CreateGamePage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final TextEditingController _textEditingController = TextEditingController();
  late String _joinCode = '';

  //Random alphanumeric generator in lambda
  final Random _rnd = Random();
  final _chars = 'abcdefghijklmnopqrstuvwxyz1234567890';
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

    await prefs.setString('nickname', _textEditingController.text);
    await prefs.setString('joinCode', _joinCode);
  }

  ///Create the server for the game state
  Future<void> _createServer() async {

    //Sign the player in to write to the database
    await FirebaseAuth.instance.signInAnonymously();

    //Initialize the database with the join code as the server ID
    DatabaseReference serverRef = FirebaseDatabase.instance.ref().child(_joinCode);
    await serverRef.set({
      'gameStart': false,
      'players': {}
    });
  }

  Future<void> _addPlayer() async {
    final String nickname = _textEditingController.text;
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    DatabaseReference playerRef = FirebaseDatabase.instance.ref().child('$_joinCode/players/$uid');
    await playerRef.set({
      'nickname': nickname,
      'score': 0
    });

  }

  ///Dispose clears the controller and any other listeners except for
  ///shared preferences
  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Create Game'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 200,
              child: TextField(
                controller: _textEditingController,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter a nickname'
                ),
                maxLength: 8,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: () {
                  if (_textEditingController.text.isNotEmpty) {
                    _createJoinCode().then((_) {
                      _createServer().then((_) {
                        _addPlayer().then((_) {
                          Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const CreateQRPage())
                          );
                        });
                      });
                    });
                  }
                },
                child: const Text('Whatacaption!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
            ),
          ],
        ),
      )
    );
  }
}