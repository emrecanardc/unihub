import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WidgetTest extends StatelessWidget {
  const WidgetTest({super.key,required this.kulupismi});
 final String kulupismi;

  Stream<QuerySnapshot> getEtkinliklerStream() {
    return FirebaseFirestore.instance
        .collection('clubs') 
        .doc(kulupismi)
        .collection('events')
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

        if (snapshot.hasError) {
          return const Center(
            child: Text('Bir hata oluştu. Lütfen tekrar deneyin.'),
          );
        }

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
            
            
            String baslik = etkinlikVerisi['eventName'] ?? 'Başlık Yok';
            String aciklama = etkinlikVerisi['description'] ?? 'Açıklama Yok';

            return Container(
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
                    baslik, 
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    aciklama, 
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                      height: 1.4,
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
