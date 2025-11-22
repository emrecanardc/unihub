import 'package:flutter/foundation.dart'; // Web kontrolü için
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:unihub/firebase_options.dart';
import 'package:unihub/login.dart'; // Mobilde açılacak ekran
import 'package:unihub/web_admin/web_admin_panel.dart'; // Webde açılacak ekran

Future<void> main() async {
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
      title: 'UniHub',
      theme: ThemeData(primarySwatch: Colors.cyan, useMaterial3: true),
      // EĞER WEB İSE -> WebAdminPanel AÇ
      // EĞER MOBİL İSE -> girisEkrani AÇ
      home: kIsWeb ? const WebAdminPanel() : const girisEkrani(),
    );
  }
}
