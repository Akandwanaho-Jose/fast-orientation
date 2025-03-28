import 'package:flutter/material.dart';
import '../../../core/utils/constants.dart'; // Import Constants

class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chatbot')),
      body: const Center(
        child: Text(
          'Chatbot Screen Content',
          style: TextStyle(color: mustBlue),
        ),
      ),
    );
  }
}
