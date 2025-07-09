import 'package:flutter/material.dart';

class OptionsScreen extends StatelessWidget {
  const OptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('オプション'),
      ),
      body: const Center(
        child: Text('ここに設定項目が入ります'),
      ),
    );
  }
}