import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final Completer<void> _uploadCompleter = Completer<void>();
  static File? _imageFile;

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

  Future<void> _uploadImage() async {
    SharedPreferences prefs = await _prefs;

    String? serverId = prefs.getString('joinCode');

    final imageRef = FirebaseStorage.instance.ref().child('$serverId');
    UploadTask uploadTask = imageRef.putFile(_imageFile!);
    await uploadTask.whenComplete(() {
      _uploadCompleter.complete();
    });
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
                ElevatedButton.icon(
                  onPressed: () {
                    _uploadImage();
                  },
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Upload')
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                    onPressed: () {
                      _uploadCompleter.future.then((_) {
                        
                      });
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