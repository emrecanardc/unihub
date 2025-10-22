import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unihub/screen_test.dart';

class WidgetTest2 extends StatelessWidget {
  const WidgetTest2({super.key});
  Stream<QuerySnapshot> getKluplerStream() {
    return FirebaseFirestore.instance.collection('clubs').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: getKluplerStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("bir hata oluştu"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Gösterilecek Klüp bulunamadı"));
        }
        final kulupler = snapshot.data!.docs;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: kulupler.map((doc) {
              var kuluplerVerisi = doc.data() as Map<String, dynamic>;
              String kulupkisaltma = kuluplerVerisi['shortName'];

              String kulupismi = kuluplerVerisi['clubName'];
              String kulupId = doc.id;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ScreenTest(kulupId: kulupId, kulupismi: kulupismi),
                    ),
                  );
                },
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.amber,
                    ),
                    child: Center(
                      child: Text(
                        kulupkisaltma,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
