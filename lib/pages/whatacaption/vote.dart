import 'dart:io';

import 'package:flutter/material.dart';

///Created by Gustavo Rubio

class VotePage extends StatefulWidget {
  const VotePage({super.key});

  @override
  State<VotePage> createState() => _VotePageState();
}

class _VotePageState extends State<VotePage> {
  final TextEditingController _textEditingController = TextEditingController();
  List<String> captions = [];
  late Future<File> _imageLink;
  static File? _imageFile;

  ///Here we will get the image from storage and download it
  Future<void> _getImage() async {

  }

  ///Get the comments from the database
  Future<void> _getComments() async {

  }

  ///Here we will send the caption to the server
  Future<void> _sendVote() async {

  }

  @override
  void initState () {
    super.initState();
    _getImage();
    _getComments();
    _sendVote();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Vote!"),
      ),
      body: SingleChildScrollView(
        child: FutureBuilder<File> (
          future: _imageLink,
          builder: (BuildContext context, AsyncSnapshot<File> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
              case ConnectionState.waiting:
                return const CircularProgressIndicator();
              case ConnectionState.active:
              case ConnectionState.done:
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Image.memory(
                          _imageFile!.readAsBytesSync(),
                          width: 300,
                          height: 300,
                          fit: BoxFit.scaleDown,
                        ),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: captions.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(captions[index], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  
                                },
                                child: const Text('Vote!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            );
                          }
                        ),
                      ],
                    ),
                  );
                }
            }
          },
        ),
      ),
    );
  }
}