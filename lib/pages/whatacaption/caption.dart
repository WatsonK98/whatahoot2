import 'package:flutter/material.dart';

class CaptionPage extends StatefulWidget {
  const CaptionPage({super.key});

  @override
  State<CaptionPage> createState() => _CaptionPageState();
}

class _CaptionPageState extends State<CaptionPage> {
  final TextEditingController _textEditingController = TextEditingController();

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
                    onPressed: (){},
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