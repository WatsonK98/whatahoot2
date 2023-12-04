import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:whatahoot2/pages/whatacaption/win.dart';

///Created by Gustavo Rubio

class VotePage extends StatefulWidget {
  const VotePage({super.key});

  @override
  State<VotePage> createState() => _VotePageState();
}

class _VotePageState extends State<VotePage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final TextEditingController _textEditingController = TextEditingController();
  List<String> captions = [];
  late String? _imageUrl;

  ///Here we will get the image from storage and download it
  Future<void> _getImage() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');

    final storageRef = FirebaseStorage.instance.ref();
    final imageRef = storageRef.child('$serverId');
    final ListResult result = await imageRef.listAll();

    if (result.items.isNotEmpty) {
      final Reference firstImage = result.items.first;
      _imageUrl = await firstImage.getDownloadURL();

      setState(() {});

    } else {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const WinPage()));
    }
  }

  ///Get the comments from the database
  Future<void> _getCaptions() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');

    DatabaseReference captionsRef = FirebaseDatabase.instance.ref().child('$serverId/captions');

  }

  Future<void> _removeCaptions() async {

  }

  Future<void> _removeImage() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');

    final storageRef = FirebaseStorage.instance.ref();
    final imageRef = storageRef.child('$serverId');
    final ListResult result = await imageRef.listAll();

    if (result.items.isNotEmpty) {
      final Reference firstImage = result.items.first;
      String imageName = firstImage.name;


    }
  }

  ///Here we will send the caption to the server
  Future<void> _sendVote() async {

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
                      onPressed: () {

                      },
                      child: const Text('Vote'),
                    ),
                  );
                }
            ),
          ],
        ),
      ),
    );
  }
}