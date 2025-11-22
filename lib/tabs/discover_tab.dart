import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unihub/screen_test.dart';
import 'package:unihub/utils/hex_color.dart';

class DiscoverClubsTab extends StatefulWidget {
  const DiscoverClubsTab({super.key});

  @override
  State<DiscoverClubsTab> createState() => _DiscoverClubsTabState();
}

class _DiscoverClubsTabState extends State<DiscoverClubsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 1. Mailden Üniversiteyi Tespit Et
  String _getUniversityFromEmail(String email) {
    if (email.endsWith('@anadolu.edu.tr')) return "Anadolu";
    if (email.endsWith('@ogrenci.estu.edu.tr')) return "ESTÜ";
    return "ESOGU"; // Varsayılan veya @ogrenci.ogu.edu.tr
  }

  // 2. Filtreleme (Kendi okulum + Üye olmadıklarım + Arama)
  Future<List<DocumentSnapshot>> _getFilteredClubs(
    List<DocumentSnapshot> allClubs,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return [];

    // Kullanıcının okulu
    String myUni = _getUniversityFromEmail(user.email!);

    List<DocumentSnapshot> filteredClubs = [];

    for (var club in allClubs) {
      var data = club.data() as Map<String, dynamic>;

      // A) OKUL KONTROLÜ: Sadece benim okulumu göster!
      // (Eski kayıtlarda 'university' yoksa varsayılan olarak ESOGU kabul et)
      String clubUni = data['university'] ?? "ESOGU";
      if (clubUni != myUni) continue;

      // B) ÜYELİK KONTROLÜ: Zaten üye olduklarımı gösterme
      var memberDoc = await club.reference
          .collection('members')
          .doc(user.uid)
          .get();
      if (memberDoc.exists) continue;

      // C) ARAMA FİLTRESİ
      if (_searchText.isNotEmpty) {
        String name = (data['clubName'] ?? "").toString().toLowerCase();
        String shortName = (data['shortName'] ?? "").toString().toLowerCase();
        String searchLower = _searchText.toLowerCase();
        if (!name.contains(searchLower) && !shortName.contains(searchLower)) {
          continue;
        }
      }

      filteredClubs.add(club);
    }

    return filteredClubs;
  }

  @override
  Widget build(BuildContext context) {
    // ... (Tasarım kodları öncekiyle AYNIDIR, sadece _getFilteredClubs değişti) ...
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text(
          "Kulüp Keşfet",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 24,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.cyan,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(
              Icons.explore,
              color: Colors.white.withOpacity(0.8),
              size: 30,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.cyan,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchText = value),
                decoration: InputDecoration(
                  hintText: "İlgi alanına göre ara...",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search, color: Colors.cyan),
                  suffixIcon: _searchText.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () => setState(() {
                            _searchController.clear();
                            _searchText = "";
                          }),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
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
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.cyan),
                  );
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return _buildEmptyState("Sistemde hiç kulüp yok.");

                return FutureBuilder<List<DocumentSnapshot>>(
                  future: _getFilteredClubs(snapshot.data!.docs),
                  builder: (context, filteredSnapshot) {
                    if (filteredSnapshot.connectionState ==
                        ConnectionState.waiting)
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.cyan),
                      );
                    var clubsToShow = filteredSnapshot.data ?? [];

                    if (clubsToShow.isEmpty) {
                      if (_searchText.isNotEmpty)
                        return _buildEmptyState("Sonuç bulunamadı.");
                      return _buildEmptyState(
                        "Okulundaki tüm kulüplere üyesin! 🎉",
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: clubsToShow.length,
                      itemBuilder: (context, index) {
                        var doc = clubsToShow[index];
                        var data = doc.data() as Map<String, dynamic>;
                        Color clubColor = hexToColor(
                          data['theme']?['primaryColor'] ?? "0xFF00BCD4",
                        );

                        // 3D Kart Tasarımı (Önceki kodla aynı)
                        return _build3DClubCard(
                          context,
                          data['clubName'] ?? 'İsimsiz',
                          data['shortName'] ?? '?',
                          data['category'] ?? 'Genel',
                          data['description'] ?? '',
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

  // --- (3D Kart Tasarımı ve EmptyState kodları önceki cevabımdan alınıp buraya eklenebilir, yer kaplamasın diye kısalttım) ---
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.saved_search, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 15),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _build3DClubCard(
    BuildContext context,
    String name,
    String shortName,
    String category,
    String description,
    String id,
    Color color,
  ) {
    String truncatedDesc = description.split(' ').take(25).join(' ') + "...";
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScreenTest(kulupId: id, kulupismi: name),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              offset: const Offset(0, 10),
              blurRadius: 20,
              spreadRadius: -5,
            ),
            BoxShadow(
              color: Colors.grey.shade300,
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(color: color.withOpacity(0.1), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      shortName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: color.withOpacity(0.5),
                    size: 20,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                truncatedDesc,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Detayları Gör",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 13,
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
