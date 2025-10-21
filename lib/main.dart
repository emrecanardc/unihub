import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'widget/widget_test.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase App',
      home: Scaffold(
        appBar: AppBar(centerTitle:true,title: const Text('Kulüp Etkinlikleri')),

        body: const WidgetTest(),
      ),
    );
  }
}
