import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:unihub/login.dart';
import 'package:unihub/screen_test.dart'; // Kulüp detay sayfası
import 'package:unihub/utils/hex_color.dart'; // Renk dönüştürücü

class MainHub extends StatefulWidget {
  const MainHub({super.key});

  @override
  State<MainHub> createState() => _MainHubState();
}

class _MainHubState extends State<MainHub> {
  int _pageIndex = 1; // Başlangıçta (1) yani Ortadaki "Kulüplerim" açılır
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  // Sayfalar
  final List<Widget> _pages = [
    const DiscoverClubsTab(), // 0: Sol - Keşfet
    const MyClubsTab(), // 1: Orta - Kulüplerim
    const UserProfileTab(), // 2: Sağ - Profil
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      // Sayfa içeriği değişiyor
      body: _pages[_pageIndex],

      // Alt Navigasyon Barı
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: _pageIndex,
        height: 60.0,
        items: const <Widget>[
          Icon(Icons.search, size: 30, color: Colors.white), // Keşfet
          Icon(Icons.home, size: 30, color: Colors.white), // Kulüplerim
          Icon(Icons.person, size: 30, color: Colors.white), // Profil
        ],
        color: Colors.cyan,
        buttonBackgroundColor: Colors.cyan.shade300,
        backgroundColor: const Color(0xFFF7F8FC), // Sayfa arkaplanıyla uyumlu
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 400),
        onTap: (index) {
          setState(() {
            _pageIndex = index;
          });
        },
        letIndexChange: (index) => true,
      ),
    );
  }
}

// ==========================================
// 1. SOL SEKME: KULÜP KEŞFETME (Renkli Tasarım)
// ==========================================
class DiscoverClubsTab extends StatelessWidget {
  const DiscoverClubsTab({super.key});

  // Üye olunmayan kulüpleri filtreleyen fonksiyon
  Future<List<DocumentSnapshot>> _getNonJoinedClubs(
    List<DocumentSnapshot> allClubs,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    List<DocumentSnapshot> filteredList = [];

    for (var club in allClubs) {
      // Her kulüp için "members" koleksiyonunda benim ID'm var mı bak
      var memberDoc = await club.reference
          .collection('members')
          .doc(user.uid)
          .get();

      // Eğer üye dökümanı YOKSA (exists == false), bu kulübü listeye ekle
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
          // Arama Çubuğu
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

          // Filtrelenmiş Liste
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

                        // Rengi Çekiyoruz
                        var theme = data['theme'] ?? {};
                        Color clubColor = hexToColor(
                          theme['primaryColor'] ?? "0xFF00BCD4",
                        );

                        return _buildClubCard(
                          context,
                          data['clubName'] ?? 'İsimsiz',
                          data['shortName'] ?? '?',
                          doc.id,
                          clubColor, // Kulüp rengini gönderiyoruz
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
}

// ==========================================
// 2. ORTA SEKME: KULÜPLERİM (Renkli Tasarım)
// ==========================================
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('clubs').snapshots(),
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

                  // Rengi Çekiyoruz
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
                      clubColor, // Kulüp rengini gönderiyoruz
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // Kulüplerim sekmesi için YATAY kart tasarımı (Renkli)
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
          // Sol tarafa ince bir renk şeridi ekleyerek şıklık katıyoruz
          border: Border(left: BorderSide(color: color, width: 5)),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1), // Kulüp renginin açığı
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

// ==========================================
// 3. SAĞ SEKME: PROFİL
// ==========================================
class UserProfileTab extends StatelessWidget {
  const UserProfileTab({super.key});

  Future<void> _cikisYap(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const girisEkrani()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          "Profilim",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.cyan,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => _cikisYap(context),
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: "Çıkış Yap",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.cyan.shade100,
                    child: Text(
                      user?.displayName?.substring(0, 1).toUpperCase() ?? "U",
                      style: const TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyan,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.cyan,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            _buildProfileField(
              "Ad Soyad",
              user?.displayName ?? "İsimsiz",
              Icons.person,
              false,
            ),
            const SizedBox(height: 16),
            _buildProfileField(
              "E-posta",
              user?.email ?? "mail@ogu.edu.tr",
              Icons.email,
              false,
            ),
            const SizedBox(height: 16),
            _buildProfileField(
              "Şifre",
              "••••••••••",
              Icons.lock,
              true,
              isPassword: true,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Bilgiler güncellendi! (Demo)"),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  "Değişiklikleri Kaydet",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField(
    String label,
    String value,
    IconData icon,
    bool isEditable, {
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5),
            ],
          ),
          child: TextField(
            enabled: isEditable,
            obscureText: isPassword,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.cyan),
              hintText: value,
              hintStyle: const TextStyle(color: Colors.black87),
              suffixIcon: isEditable
                  ? const Icon(Icons.edit, color: Colors.grey)
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
            ),
            controller: isEditable ? null : TextEditingController(text: value),
          ),
        ),
      ],
    );
  }
}

// Ortak Kart Tasarımı (DİKEY - RENKLİ)
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
        // İsteğe bağlı: Kartın altına ince bir renk çizgisi
        border: Border(bottom: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
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
