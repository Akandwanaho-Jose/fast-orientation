import 'package:flutter/material.dart';
import '../../../core/utils/constants.dart'; // Import Constants

class FaqScreen extends StatelessWidget {
  const FaqScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Frequently Asked Questions')),
      body: const Center(
        child: Text(
          'Frequently Asked Questions Screen Content',
          style: TextStyle(color: mustBlue),
        ),
      ),
    );
  }
}
