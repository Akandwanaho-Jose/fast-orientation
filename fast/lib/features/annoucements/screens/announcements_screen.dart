import 'package:flutter/material.dart';
import '../../../core/utils/constants.dart'; // Import Constants

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: const Center(
        child: Text(
          'Announcements Screen Content',
          style: TextStyle(color: mustBlue),
        ),
      ),
    );
  }
}
