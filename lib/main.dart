import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:unihub/login.dart';
import 'package:unihub/register.dart';
import 'package:unihub/widget/widget_Test2.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const girisEkrani());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UniHub',
      home: Scaffold(
        body: Container(
          width: 400,
          height: 500,
          padding: EdgeInsets.all(10),
          child: WidgetTest2(),
        ),
      ),
    );
  }
}
