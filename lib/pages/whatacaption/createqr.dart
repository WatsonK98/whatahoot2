import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateQRPage extends StatefulWidget {
  const CreateQRPage({super.key});

  @override
  State<CreateQRPage> createState() => _CreateQRPageState();
}

class _CreateQRPageState extends State<CreateQRPage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late String _code;

  @override
  void initState() {
    super.initState();
    _code = _prefs.then((SharedPreferences prefs) {
      return prefs.getString('joinCode');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('QR'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          QrImageView(
            data: '123',
            version: QrVersions.auto,
            size: 200,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('123'),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Continue')
              ),
            ],
          )
        ],
      ),
    );
  }
}