import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:unihub/tabs/discover_tab.dart';
import 'package:unihub/tabs/my_clubs_tab.dart';
import 'package:unihub/tabs/user_profile_tab.dart';

class MainHub extends StatefulWidget {
  const MainHub({super.key});

  @override
  State<MainHub> createState() => _MainHubState();
}

class _MainHubState extends State<MainHub> {
  int _pageIndex = 1; // Başlangıçta "Kulüplerim"
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  final List<Widget> _pages = [
    const DiscoverClubsTab(), // Sol: Keşfet
    const MyClubsTab(), // Orta: Kulüplerim
    const UserProfileTab(), // Sağ: Profil
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: _pages[_pageIndex],
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: _pageIndex,
        height: 60.0,
        items: const <Widget>[
          Icon(Icons.search, size: 30, color: Colors.white),
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.person, size: 30, color: Colors.white),
        ],
        color: Colors.cyan,
        buttonBackgroundColor: Colors.cyan.shade300,
        backgroundColor: const Color(0xFFF7F8FC),
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 400),
        onTap: (index) {
          setState(() {
            _pageIndex = index;
          });
        },
        letIndexChange: (index) => true,
      ),
    );
  }
}
