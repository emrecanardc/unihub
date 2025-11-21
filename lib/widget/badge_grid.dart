import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BadgeGrid extends StatelessWidget {
  final String clubId;
  final String userId;
  final Color themeColor;

  const BadgeGrid({
    super.key,
    required this.clubId,
    required this.userId,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clubs')
          .doc(clubId)
          .collection('members')
          .doc(userId)
          .collection('badges')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 40,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 5),
                const Text(
                  "Henüz kazanılmış rozet yok.",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var badge =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.star, color: themeColor, size: 30),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    badge['badgeName'] ?? 'Rozet',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
