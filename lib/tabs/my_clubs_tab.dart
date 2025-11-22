import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unihub/screen_test.dart';
import 'package:unihub/utils/hex_color.dart';
import 'package:unihub/widget/sponsor_banner.dart';

class MyClubsTab extends StatelessWidget {
  const MyClubsTab({super.key});

  // --- ROL AYARLARI (Sıralama ve İsimlendirme) ---
  int _getRolePriority(String? role) {
    switch (role) {
      case 'baskan':
        return 0;
      case 'baskan_yardimcisi':
        return 1;
      case 'koordinator':
        return 2;
      default:
        return 3;
    }
  }

  String _getRoleLabel(String? role) {
    switch (role) {
      case 'baskan':
        return 'Başkan';
      case 'baskan_yardimcisi':
        return 'Başkan Yrd.';
      case 'koordinator':
        return 'Koordinatör';
      default:
        return 'Üye';
    }
  }

  // --- VERİ ÇEKME ---
  Future<List<Map<String, dynamic>>> _fetchAndSortMyClubs(String userId) async {
    QuerySnapshot clubsSnapshot = await FirebaseFirestore.instance
        .collection('clubs')
        .get();
    List<Map<String, dynamic>> myClubs = [];

    for (var doc in clubsSnapshot.docs) {
      var memberDoc = await doc.reference
          .collection('members')
          .doc(userId)
          .get();
      if (memberDoc.exists) {
        var clubData = doc.data() as Map<String, dynamic>;
        var memberData = memberDoc.data() as Map<String, dynamic>;

        myClubs.add({
          'id': doc.id,
          'clubName': clubData['clubName'] ?? 'İsimsiz',
          'shortName': clubData['shortName'] ?? '?',
          'theme': clubData['theme'] ?? {},
          'role': memberData['role'] ?? 'uye',
        });
      }
    }

    // Sıralama: Başkan -> Yrd -> Koordinatör -> Üye
    myClubs.sort(
      (a, b) =>
          _getRolePriority(a['role']).compareTo(_getRolePriority(b['role'])),
    );
    return myClubs;
  }

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
          const SponsorBanner(), // Sponsor Alanı

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchAndSortMyClubs(user!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.cyan),
                  );
                }

                var clubs = snapshot.data ?? [];
                if (clubs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_off,
                          size: 60,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Henüz bir kulübe katılmadın.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: clubs.length,
                  itemBuilder: (context, index) {
                    final club = clubs[index];
                    Color clubColor = hexToColor(
                      club['theme']['primaryColor'] ?? "0xFF00BCD4",
                    );
                    String role = club['role'];

                    return _buildClubListTile(
                      context,
                      club['clubName'],
                      club['shortName'],
                      club['id'],
                      role,
                      clubColor,
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

  // --- RESİMDEKİ SADE TASARIM ---
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
        margin: const EdgeInsets.only(bottom: 16),
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
          // Sol tarafa kulübün renginde ince bir şerit (Resimdeki detay)
          border: Border(left: BorderSide(color: color, width: 5)),
        ),
        child: Row(
          children: [
            // 1. KULÜP KISALTMASI (Renkli Daire İçinde)
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // 2. İSİM VE ROL
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Rol Etiketi (Resimdeki gibi küçük kutucuk)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: role == 'baskan'
                          ? Colors.amber
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getRoleLabel(role),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: role == 'baskan' ? Colors.white : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. OK İKONU
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
