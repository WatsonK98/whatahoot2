import 'package:flutter/material.dart';
import 'package:whatahoot2/pages/creategame.dart';
import 'package:whatahoot2/pages/joingame.dart';

///Created by Adrian Urquizo
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Whatahoot'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const JoinGamePage())
                );
              },
              child: const Text('Join Game', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const CreateGamePage())
                );
              },
              child: const Text('Create Game', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
            ),
          ],
        ),
      ),
    );
  }
}