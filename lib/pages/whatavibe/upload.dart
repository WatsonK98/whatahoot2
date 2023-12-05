import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'vote.dart';

///Created by David Vazquez

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();
  late bool gameReady = false;
  late bool ready = false;
  static File? _imageFile;
  var filePath = 'data.txt';
  static File? _imageDataFile;

  ///Get image from device
  Future<void> _getImage() async {
    ImagePicker picker = ImagePicker();
    XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return;
    }

    //Set the state to hold the image file
    setState(() {
      _imageFile = File(image.path);
    });
  }

  //Write the entered data to a file
  Future<void> _writeData() async {
    var file = File(filePath);

    if (!file.existsSync()) {
      file.createSync();
    }

    var fileSink = file.openWrite();
    fileSink.write('${_titleController.text}\n${_artistController.text}');
    fileSink.close();

    setState(() {
      _imageDataFile = file;
    });
  }

  ///Upload the Image to the server with its data
  Future<void> _uploadImage() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');

    final imageRef = FirebaseStorage.instance.ref().child('$serverId/${_titleController.text}');
    await imageRef.putFile(_imageFile!);
    await imageRef.putFile(_imageDataFile!);
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
      'gameStage': 1
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
    if (snapshot.value == 1) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Upload!'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 16),
            Center(
              child:
              _imageFile != null
              ? Image.memory(
              _imageFile!.readAsBytesSync(),
              width: 300,
              height: 300,
                fit: BoxFit.scaleDown,
              )
              : Container(height: 300),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 16),
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter a Title',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _artistController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter an Artist',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _getImage();
                  },
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Upload', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {

                    if (_imageFile != null && _titleController.text.isNotEmpty && _artistController.text.isNotEmpty) {
                      await _writeData();
                      await _uploadImage();
                      await _updatePlayerReady();
                      await _isHost();

                      if (ready || gameReady) {
                        await _updatePlayerNotReady();
                        Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const VotePage()));
                      }
                    }
                  },
                  child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}