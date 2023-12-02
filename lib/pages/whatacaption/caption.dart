import 'dart:io';

import 'package:flutter/material.dart';

class CaptionPage extends StatefulWidget {
  const CaptionPage({super.key});

  @override
  State<CaptionPage> createState() => _CaptionPageState();
}

class _CaptionPageState extends State<CaptionPage> {
  final TextEditingController _textEditingController = TextEditingController();
  late Future<File> _imageLink;
  static File? _imageFile;

  Future<void> _getImage() async {

  }

  Future<void> _sendCaption() async {

  }

  @override
  void initState () {
    super.initState();
    _getImage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Caption!"),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FutureBuilder<File> (
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
                        return Image.memory(
                          _imageFile!.readAsBytesSync(),
                          width: 300,
                          height: 300,
                          fit: BoxFit.scaleDown,
                        );
                      }
                  }
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _textEditingController,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter a caption!'
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: (){
                      if (_textEditingController.text.isNotEmpty) {
                        //send the caption, wait, then move on
                      }
                    },
                    child: const Text('Continue!'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}