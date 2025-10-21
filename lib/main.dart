import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:unihub/screen_test.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ScreenTest());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
          // dokümanını getirmesini istiyoruz.
          future: FirebaseFirestore.instance
              .collection('test')
              .doc('il_Veri')
              .get(),
              
          //  duruma göre ne yapacağını söyleyen kısım.
          builder: (context, snapshot) {

            // hazırlanıyor... 
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator()); // Yükleniyor animasyonu göster.
            }

            //  bir sorun çıktı! 
            if (snapshot.hasError) {
              return Center(child: Text("Bir hata oluştu!")); // Hata mesajı göster.
            }

            // içinde veri var! 
            if (snapshot.hasData && snapshot.data!.exists) {
              
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

            // (doküman bulunamadı).
            return Center(child: Text("Veri bulunamadı."));
          },
        ),
      ),
    );
  }
}