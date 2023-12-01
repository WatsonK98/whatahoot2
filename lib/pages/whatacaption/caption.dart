import 'package:flutter/material.dart';

class CaptionPage extends StatefulWidget {
  const CaptionPage({super.key});

  @override
  State<CaptionPage> createState() => _captionPageState();
}

class _captionPageState extends State<CaptionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Caption!"),
      ),
    );
  }
}