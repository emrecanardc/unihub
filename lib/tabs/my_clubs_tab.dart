import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unihub/screen_test.dart';
import 'package:unihub/utils/hex_color.dart';
import 'package:unihub/widget/sponsor_banner.dart';

class MyClubsTab extends StatelessWidget {
  const MyClubsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          "Kulüplerim",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.cyan,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          const SponsorBanner(),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('clubs')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: snapshot.data!.docs.map((doc) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: doc.reference
                          .collection('members')
                          .doc(user?.uid)
                          .get(),
                      builder: (context, memberSnap) {
                        if (!memberSnap.hasData || !memberSnap.data!.exists) {
                          return const SizedBox.shrink();
                        }

                        var data = doc.data() as Map<String, dynamic>;
                        var theme = data['theme'] ?? {};
                        Color clubColor = hexToColor(
                          theme['primaryColor'] ?? "0xFF00BCD4",
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: _buildClubListTile(
                            context,
                            data['clubName'] ?? 'İsimsiz',
                            data['shortName'] ?? '?',
                            doc.id,
                            memberSnap.data!['role'] ?? 'uye',
                            clubColor,
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubListTile(
    BuildContext context,
    String name,
    String shortName,
    String id,
    String role,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScreenTest(kulupId: id, kulupismi: name),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border(left: BorderSide(color: color, width: 5)),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  shortName,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: role == 'baskan'
                          ? Colors.amber
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      role == 'baskan'
                          ? 'Başkan'
                          : (role == 'yonetim' ? 'Yönetim' : 'Üye'),
                      style: TextStyle(
                        fontSize: 12,
                        color: role == 'baskan' ? Colors.white : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: color.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}
