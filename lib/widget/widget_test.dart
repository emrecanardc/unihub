import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WidgetTest extends StatelessWidget {
  const WidgetTest({super.key});
  Stream<QuerySnapshot> getEtkinliklerStream() {
    return FirebaseFirestore.instance
        .collection('kulüpler')
        .doc('matematikkulubu')
        .collection('etkinlikler')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: getEtkinliklerStream(),

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // --- DURUM 2: Bir Hata Oluştu ---
        if (snapshot.hasError) {
          return const Center(
            child: Text('Bir hata oluştu. Lütfen tekrar deneyin.'),
          );
        }

        // --- DURUM 3: Veri Geldi ama Boş ---
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Gösterilecek etkinlik bulunamadı.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        final etkinlikler = snapshot.data!.docs;
        return ListView.builder(
          itemCount: etkinlikler.length,
          itemBuilder: (BuildContext context, int index) {
            var etkinlikVerisi =
                etkinlikler[index].data() as Map<String, dynamic>;
            String baslik = etkinlikVerisi['baslik'] ?? 'Başlık Yok';
            String aciklama = etkinlikVerisi['aciklama'] ?? 'Açıklama Yok';
            return Container(
              // Bu Container, senin orijinal tasarımın
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    baslik, // <-- VERİ BURAYA GELİYOR
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    aciklama, // <-- VERİ BURAYA GELİYOR
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                      height: 1.4, // Satır yüksekliği
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
