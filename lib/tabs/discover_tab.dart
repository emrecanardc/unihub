import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unihub/screen_test.dart';
import 'package:unihub/utils/hex_color.dart';

class DiscoverClubsTab extends StatelessWidget {
  const DiscoverClubsTab({super.key});

  Future<List<DocumentSnapshot>> _getNonJoinedClubs(
    List<DocumentSnapshot> allClubs,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    List<DocumentSnapshot> filteredList = [];

    for (var club in allClubs) {
      var memberDoc = await club.reference
          .collection('members')
          .doc(user.uid)
          .get();
      if (!memberDoc.exists) {
        filteredList.add(club);
      }
    }
    return filteredList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          "Kulüp Keşfet",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.cyan,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Colors.cyan,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Yeni topluluklar ara...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('clubs')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Hiç kulüp bulunamadı."));
                }

                return FutureBuilder<List<DocumentSnapshot>>(
                  future: _getNonJoinedClubs(snapshot.data!.docs),
                  builder: (context, filteredSnapshot) {
                    if (filteredSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.cyan),
                      );
                    }

                    var clubsToShow = filteredSnapshot.data ?? [];

                    if (clubsToShow.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 60,
                              color: Colors.cyan.shade200,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Tüm kulüplere zaten üyesin! 🎉",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: clubsToShow.length,
                      itemBuilder: (context, index) {
                        var doc = clubsToShow[index];
                        var data = doc.data() as Map<String, dynamic>;
                        var theme = data['theme'] ?? {};
                        Color clubColor = hexToColor(
                          theme['primaryColor'] ?? "0xFF00BCD4",
                        );

                        return _buildClubCard(
                          context,
                          data['clubName'] ?? 'İsimsiz',
                          data['shortName'] ?? '?',
                          doc.id,
                          clubColor,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubCard(
    BuildContext context,
    String name,
    String shortName,
    String id,
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  shortName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
