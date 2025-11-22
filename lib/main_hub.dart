import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:unihub/login.dart';
import 'package:unihub/screen_test.dart'; // Kulüp detay sayfası
import 'package:unihub/utils/hex_color.dart'; // Renk dönüştürücü
import 'package:unihub/widget/sponsor_banner.dart'; // YENİ EKLENEN WIDGET

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
      body: _pages[_pageIndex],
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: _pageIndex,
        height: 60.0,
        items: const <Widget>[
          Icon(Icons.search, size: 30, color: Colors.white),
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.person, size: 30, color: Colors.white),
        ],
        color: Colors.cyan,
        buttonBackgroundColor: Colors.cyan.shade300,
        backgroundColor: const Color(0xFFF7F8FC),
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
// 1. SOL SEKME: KULÜP KEŞFETME
// ==========================================
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
}

// ==========================================
// 2. ORTA SEKME: KULÜPLERİM (Sponsor Banner Burada)
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
      body: Column(
        children: [
          // 👇 SPONSOR BANNER BURADA!
          const SponsorBanner(),

          // KULÜP LİSTESİ
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

// ==========================================
// 3. SAĞ SEKME: PROFİL (GELİŞMİŞ & GÜVENLİ)
// ==========================================
class UserProfileTab extends StatefulWidget {
  const UserProfileTab({super.key});

  @override
  State<UserProfileTab> createState() => _UserProfileTabState();
}

class _UserProfileTabState extends State<UserProfileTab> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _newPasswordController;

  bool _isObscured = true; // Yeni şifreyi gizle/göster
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? "");
    _emailController = TextEditingController(text: user?.email ?? "");
    _newPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  // 1. GÜVENLİK DİALOGU: Mevcut şifreyi sor
  Future<void> _showReAuthDialog() async {
    final passwordController = TextEditingController();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.security, color: Colors.cyan),
              SizedBox(width: 10),
              Text("Güvenlik Doğrulaması"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Değişiklikleri kaydetmek için lütfen MEVCUT şifrenizi girin.",
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Mevcut Şifre",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context); // Dialogu kapat
                _saveChanges(passwordController.text.trim()); // İşlemi başlat
              },
              child: const Text("Onayla"),
            ),
          ],
        );
      },
    );
  }

  // 2. DEĞİŞİKLİKLERİ KAYDETME İŞLEMİ
  Future<void> _saveChanges(String currentPassword) async {
    if (currentPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("İşlem için mevcut şifrenizi girmelisiniz."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // A) Önce kullanıcıyı doğrula (Re-authenticate)
      // Firebase kritik işlemlerde bunu şart koşar.
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // B) İsim Değişikliği Varsa
      if (_nameController.text.trim() != user.displayName) {
        await user.updateDisplayName(_nameController.text.trim());
        // Firestore'daki veriyi de güncellemek istersen buraya ekleyebilirsin
        // await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'name': ...});
      }

      // C) Şifre Değişikliği Varsa
      if (_newPasswordController.text.isNotEmpty) {
        if (_newPasswordController.text.length < 6) {
          throw FirebaseAuthException(
            code: 'weak-password',
            message: "Yeni şifre en az 6 karakter olmalı.",
          );
        }
        await user.updatePassword(_newPasswordController.text.trim());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profil başarıyla güncellendi! ✅"),
            backgroundColor: Colors.green,
          ),
        );
        _newPasswordController.clear(); // Şifre alanını temizle
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Bir hata oluştu.";
      if (e.code == 'wrong-password')
        msg = "Mevcut şifreyi yanlış girdiniz.";
      else if (e.code == 'weak-password')
        msg = "Yeni şifre çok zayıf.";
      else if (e.code == 'requires-recent-login')
        msg = "Lütfen çıkış yapıp tekrar girin.";

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 3. ÇIKIŞ YAPMA
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
            // --- PROFİL FOTOĞRAFI ---
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

            const SizedBox(height: 40),

            // --- AD SOYAD (DEĞİŞTİRİLEBİLİR) ---
            _buildLabel("Ad Soyad"),
            _buildTextField(
              controller: _nameController,
              icon: Icons.person,
              hint: "Adınız Soyadınız",
            ),

            const SizedBox(height: 20),

            // --- E-POSTA (KİLİTLİ) ---
            _buildLabel("E-posta"),
            _buildTextField(
              controller: _emailController,
              icon: Icons.email,
              isReadOnly: true,
            ),

            const SizedBox(height: 20),

            // --- YENİ ŞİFRE (İSTEĞE BAĞLI) ---
            _buildLabel("Şifre"),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5),
                ],
              ),
              child: TextField(
                controller: _newPasswordController,
                obscureText: _isObscured,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Colors.cyan,
                  ),
                  hintText: "Yeni Şifre (Değiştirmek istemiyorsan boş bırak)",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscured ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(() => _isObscured = !_isObscured),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // --- KAYDET BUTONU ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : _showReAuthDialog, // Tıklayınca Dialog Aç
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Değişiklikleri Kaydet",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    bool isReadOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isReadOnly
            ? Colors.grey.shade200
            : Colors.white, // Kilitliyse gri
        borderRadius: BorderRadius.circular(12),
        boxShadow: isReadOnly
            ? []
            : [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
      ),
      child: TextField(
        controller: controller,
        readOnly: isReadOnly,
        enabled: !isReadOnly,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: isReadOnly ? Colors.grey : Colors.cyan),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black87),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    );
  }
}

Widget _buildProfileField(
  String label,
  String value,
  IconData icon, {
  bool isPassword = false,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
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
          enabled: false, // Şimdilik sadece görüntüleme
          obscureText: isPassword,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.cyan),
            hintText: value,
            hintStyle: const TextStyle(color: Colors.black87),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
          ),
          controller: TextEditingController(text: value),
        ),
      ),
    ],
  );
}

// Kart Widget'ı (Keşfet Sekmesi İçin)
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
