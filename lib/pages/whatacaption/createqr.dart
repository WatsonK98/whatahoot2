import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:whatahoot2/pages/whatacaption/upload.dart';

///Created by Alexander Watson

class CreateCaptionQRPage extends StatefulWidget {
  const CreateCaptionQRPage({super.key});

  @override
  State<CreateCaptionQRPage> createState() => _CreateCaptionQRPageState();
}

class _CreateCaptionQRPageState extends State<CreateCaptionQRPage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<String> _joinCode;
  late int _playerCount = 1;

  void _initPlayerListener() async {
    DatabaseReference playersRef = FirebaseDatabase.instance.ref().child('$_joinCode/players');
    playersRef.onChildAdded.listen((event) {
      print('something happened');
      print(event.snapshot.value);
      setState(() {
        _playerCount++;
      });
    });
  }

  ///Save a count of the players for later
  Future<void> _savePlayerCount() async {
    SharedPreferences prefs = await _prefs;
    await prefs.setInt('playerCount', _playerCount);
  }

  ///If the host then update the game state
  Future<void> _updateGameStage() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');

    DatabaseReference serverRef = FirebaseDatabase.instance.ref().child('$serverId');
    await serverRef.update({
      'gameStage': 1
    });
  }

  @override
  void initState() {
    super.initState();

    _joinCode = _prefs.then((SharedPreferences prefs) {
      return prefs.getString('joinCode') ?? '';
    });

    _initPlayerListener();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Join Me!'),
      ),
      body: Center(
        child: FutureBuilder(
          future: _joinCode,
          builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
              case ConnectionState.waiting:
                return const CircularProgressIndicator();
              case ConnectionState.active:
              case ConnectionState.done:
                if(snapshot.hasError) {
                  return const Text('Error loading QR code');
                } else {
                  return SingleChildScrollView(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          QrImageView(
                            data: '$snapshot.data',
                            version: QrVersions.auto,
                            size: 220,
                          ),
                          const SizedBox(height: 16),
                          Text("${snapshot.data}", style: const TextStyle(fontSize: 45, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Text('$_playerCount', style: const TextStyle(fontSize: 55)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                              onPressed: () async {
                                await _savePlayerCount();
                                await _updateGameStage();
                                Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => const UploadPage()));
                              },
                              child: const Text("Continue", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                          ),
                        ],
                      ),
                    ),
                  );
                }
            }
          }
        ),
      ),
    );
  }
}