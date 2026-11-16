import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundImage: NetworkImage(
                'https://avatars.githubusercontent.com/u/118288247?v=4&size=64',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Erlangga Hidayatullah',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1C),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Account settings coming soon',
              style: TextStyle(fontSize: 14, color: Color(0xFF87879D)),
            ),
          ],
        ),
      ),
    );
  }
}
