import 'package:flutter/material.dart';

class SuperAdminCourtScreen extends StatelessWidget {
  final String courtId;
  const SuperAdminCourtScreen({super.key, required this.courtId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF068631),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Court Details'),
      ),
      body: const Center(
        child: Text(
          'Coming soon.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}
