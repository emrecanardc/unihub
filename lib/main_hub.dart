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
  int _pageIndex = 1; // Başlangıçta ortadaki "Kulüplerim" sekmesi açık olsun
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  // Sayfa Listesi
  final List<Widget> _pages = [
    const DiscoverClubsTab(), // 0: Sol - Keşfet
    const MyClubsTab(), // 1: Orta - Kulüplerim
    const UserProfileTab(), // 2: Sağ - Profil
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Arka plan rengi tüm sayfalarda ortak olsun
      backgroundColor: const Color(0xFFF7F8FC),

      // Alt Menü (Navigation Bar)
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: _pageIndex,
        height: 60.0,
        items: const <Widget>[
          Icon(Icons.search, size: 30, color: Colors.white), // Sol: Keşfet
          Icon(Icons.home, size: 30, color: Colors.white), // Orta: Kulüplerim
          Icon(Icons.person, size: 30, color: Colors.white), // Sağ: Profil
        ],
        color: Colors.cyan,
        buttonBackgroundColor: Colors.cyan.shade300,
        backgroundColor: Colors.transparent, // Sayfa içeriğiyle uyumlu olsun
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 400),
        onTap: (index) {
          setState(() {
            _pageIndex = index;
          });
        },
        letIndexChange: (index) => true,
      ),

      // Seçili Sayfa İçeriği
      // Burada "IndexedStack" kullanarak sayfaların durumunu koruyoruz (scroll pozisyonu vb.)
      body: IndexedStack(index: _pageIndex, children: _pages),
    );
  }
}
