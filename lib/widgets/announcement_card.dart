import 'package:flutter/material.dart';

class AnnouncementCard extends StatelessWidget {
  final String announcement;

  const AnnouncementCard({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, Colors.orange.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: const Icon(Icons.campaign, color: Colors.deepOrange, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Update from Tailor',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    announcement,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: Colors.brown.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
