import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'caption.dart';

///Created by David Vazquez

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final Completer<void> _uploadCompleter = Completer<void>();
  static File? _imageFile;

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

  ///Upload the Image to the server
  Future<void> _uploadImage() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');
    String? fileName = _imageFile?.path.split('/').last;

    final imageRef = FirebaseStorage.instance.ref().child('$serverId/$fileName');
    UploadTask task = imageRef.putFile(_imageFile!);
    task.snapshotEvents.listen((TaskSnapshot snapshot) {
      if (snapshot.bytesTransferred == snapshot.totalBytes) {
        _uploadCompleter.complete();
      }
    });
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
      'gameStage': 2
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
      await _updatePlayerNotReady();
      Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const CaptionPage()));
    }
  }

  ///If not the host then await for stage change
  Future<void> _listenGameStage() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');

    DatabaseReference serverRef = FirebaseDatabase.instance.ref().child('$serverId/gameStage');

    DataSnapshot snapshot = await serverRef.get();
    if (snapshot.value == 2) {
      Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const CaptionPage()));
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
              child: _imageFile != null
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
                ElevatedButton.icon(
                  onPressed: () async {
                    if(!_uploadCompleter.isCompleted){
                      await _getImage();
                      await _uploadImage();
                      await _updatePlayerReady();
                    } else {
                      null;
                    }
                  },
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Upload', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (_imageFile != null && _uploadCompleter.isCompleted) {
                      await _isHost();
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