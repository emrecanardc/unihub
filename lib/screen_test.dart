import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:unihub/widget/widget_test.dart';

class ScreenTest extends StatefulWidget {
  final String kulupId;
  final String kulupismi;
  const ScreenTest({
    super.key,
    required this.kulupId,
    required this.kulupismi,
  });

  @override
  State<ScreenTest> createState() => _ScreenTestState();
}

class _ScreenTestState extends State<ScreenTest> {
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color.fromARGB(255, 218, 217, 217),
        appBar: AppBar(
          backgroundColor: Colors.cyan,
          centerTitle: true,
          leading: BackButton(
            onPressed: Navigator.of(context).pop,

            
          ),
          
          title: Text(
            widget.kulupismi,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
        body: Column(
          children: [
            Container(
              width: 400,
              height: 300,
              child: WidgetTest(kulupismi: widget.kulupId,),
              color: Colors.amber,
            ),
            SizedBox(height: 10,),
            Container(width: 400,
              height: 300,
              
              color: Colors.blue,)
          ],
          
        ),

        bottomNavigationBar: CurvedNavigationBar(
          items: [
            Icon(Icons.add, size: 30),
            Icon(Icons.home, size: 30),
            Icon(Icons.compare_arrows, size: 30),
          ],
          height: 60,

          backgroundColor: const Color.fromARGB(255, 218, 217, 217),
        ),
      ),
    );
  }
}
