import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unihub/screen_test.dart'; // Kulüp detay sayfası
import 'package:unihub/login.dart'; // Çıkış yapınca dönülecek yer

class WidgetTest2 extends StatelessWidget {
  const WidgetTest2({super.key});

  // Veritabanından kulüpleri çeken fonksiyon
  Stream<QuerySnapshot> getKluplerStream() {
    return FirebaseFirestore.instance.collection('clubs').snapshots();
  }

  // Güvenli Çıkış Yapma Fonksiyonu
  Future<void> _cikisYap(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      // Giriş ekranına geri dön ve geçmişi sil
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const girisEkrani()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC), // Hafif gri modern arka plan
      // 1. Üst Bar (AppBar)
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "ÜniHub Kulüpler",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          // Çıkış Yap Butonu
          IconButton(
            onPressed: () => _cikisYap(context),
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            tooltip: "Çıkış Yap",
          ),
        ],
      ),

      body: Column(
        children: [
          // 2. Arama Çubuğu (Search Bar)
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Colors.cyan,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Kulüp veya topluluk ara...",
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

          // 3. Kulüp Listesi (Grid)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getKluplerStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.cyan),
                  );
                }
                if (snapshot.hasError) {
                  return const Center(child: Text("Bir hata oluştu :("));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sentiment_dissatisfied,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Henüz aktif kulüp bulunmuyor.",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                final kulupler = snapshot.data!.docs;

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Yan yana 2 kutu
                    crossAxisSpacing: 16, // Yatay boşluk
                    mainAxisSpacing: 16, // Dikey boşluk
                    childAspectRatio: 0.85, // Kartın en-boy oranı (Dikdörtgen)
                  ),
                  itemCount: kulupler.length,
                  itemBuilder: (context, index) {
                    var veriler =
                        kulupler[index].data() as Map<String, dynamic>;
                    String kulupAdi = veriler['clubName'] ?? 'İsimsiz';
                    String kisaAd = veriler['shortName'] ?? '?';
                    String kulupId = kulupler[index].id;

                    return _buildClubCard(context, kulupAdi, kisaAd, kulupId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Şık Kart Tasarımı Widget'ı
  Widget _buildClubCard(
    BuildContext context,
    String name,
    String shortName,
    String id,
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
              offset: const Offset(0, 4), // Gölge yönü
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Daire İkon
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.cyan.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  shortName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Kulüp İsmi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis, // Uzun isimleri ... yapar
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
