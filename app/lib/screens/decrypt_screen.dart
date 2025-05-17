import 'package:flutter/material.dart';

class DecryptScreen extends StatefulWidget {
  const DecryptScreen({super.key});

  @override
  State<DecryptScreen> createState() => _DecryptScreenState();
}

class _DecryptScreenState extends State<DecryptScreen> {
  final TextEditingController _keyController = TextEditingController();
  
  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Decrypt Content'),
      ),
      body: const Center(
        child: Text('Coming Soon'),
      ),
    );
  }
}