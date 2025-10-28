import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:unihub/login.dart';
import 'package:unihub/widget/widget_Test2.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const Login());
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
      home: Login()

      // body: Container(width: 400,height: 500,padding: EdgeInsets.all(10),child: WidgetTest2(),)
    );
  }
}
