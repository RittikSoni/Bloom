import 'package:flutter/material.dart';

class MinimalTemplateWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? avatarUrl;

  const MinimalTemplateWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (avatarUrl != null)
            CircleAvatar(radius: 40, backgroundImage: NetworkImage(avatarUrl!)),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          const Text(
            '00:00',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
