import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:whatahoot2/pages/whatacaption/upload.dart';

///Created by Alexander Watson

class CreateQRPage extends StatefulWidget {
  const CreateQRPage({super.key});

  @override
  State<CreateQRPage> createState() => _CreateQRPageState();
}

class _CreateQRPageState extends State<CreateQRPage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<String> _joinCode;
  late int _playerCount = 1;

  Future<void> _savePlayerCount() async {
    SharedPreferences prefs = await _prefs;
    await prefs.setInt('playerCount', _playerCount);
  }

  @override
  void initState() {
    super.initState();
    _joinCode = _prefs.then((SharedPreferences prefs) {
      return prefs.getString('joinCode') ?? '';
    });

    DatabaseReference playersRef = FirebaseDatabase.instance.ref().child('$_joinCode/players');
    playersRef.onChildAdded.listen((event) {
      setState(() {
        _playerCount++;
      });
    });
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
                  return Column(
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
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const UploadPage()));
                        },
                        child: const Text("Continue", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                      ),
                    ],
                  );
                }
            }
          }
        ),
      ),
    );
  }
}