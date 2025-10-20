import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.purple,
          title: Text(
            "Firestore Veri Testi",
            style: TextStyle(color: Colors.white),
          ),
        ),
        // Bu widget, gelecekte gelecek bir veri için bekler ve duruma göre ekranı çizer.
        body: FutureBuilder<DocumentSnapshot>( // Ne tür bir veri beklediğini belirtmek iyidir.
          // 1. SİPARİŞ: Firestore'dan 'test/ilk_veri' dokümanını getirmesini istiyoruz.
          future: FirebaseFirestore.instance
              .collection('test')
              .doc('il_Veri')
              .get(),
              
          // 2. GARSON: Siparişin durumuna göre ne yapacağını söyleyen kısım.
          builder: (context, snapshot) {

            // DURUM A: Sipariş yolda, hala hazırlanıyor... ⏳
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator()); // Yükleniyor animasyonu göster.
            }

            // DURUM B: Siparişte bir sorun çıktı! ❌
            if (snapshot.hasError) {
              return Center(child: Text("Bir hata oluştu!")); // Hata mesajı göster.
            }

            // DURUM C: Sipariş geldi ve içinde veri var! ✅
            if (snapshot.hasData && snapshot.data!.exists) {
              // Gelen veriyi (paketi) açıp içinden "mesaj" alanını alıyoruz.
              var data = snapshot.data!.data() as Map<String, dynamic>;
              String mesaj = data['mesaj'] ?? "Mesaj bulunamadı"; // Eğer 'mesaj' yoksa varsayılan metin.

              // Ekrana bu mesajı yazdırıyoruz.
              return Center(
                child: Text(
                  mesaj,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              );
            }

            // DURUM D: Sipariş geldi ama içi boşmuş (doküman bulunamadı).
            return Center(child: Text("Veri bulunamadı."));
          },
        ),
      ),
    );
  }
}