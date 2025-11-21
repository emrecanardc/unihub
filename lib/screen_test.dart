import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:unihub/utils/hex_color.dart';
import 'package:unihub/tabs/club_about_tab.dart';
import 'package:unihub/tabs/club_events_tab.dart';
import 'package:unihub/tabs/club_profile_tab.dart';

class ScreenTest extends StatefulWidget {
  final String kulupId;
  final String kulupismi;

  const ScreenTest({super.key, required this.kulupId, required this.kulupismi});

  @override
  State<ScreenTest> createState() => _ScreenTestState();
}

class _ScreenTestState extends State<ScreenTest> {
  int _pageIndex = 1;
  late Future<DocumentSnapshot> _clubDataFuture;
  late PageController _pageController;

  // İkon Haritası (Admin Paneli ile aynı olmalı)
  final Map<String, IconData> _clubIcons = {
    'groups': Icons.groups,
    'school': Icons.school,
    'science': Icons.science,
    'sports_soccer': Icons.sports_soccer,
    'music_note': Icons.music_note,
    'brush': Icons.brush,
    'computer': Icons.computer,
    'book': Icons.book,
    'camera_alt': Icons.camera_alt,
    'theater_comedy': Icons.theater_comedy,
    'eco': Icons.eco,
    'gavel': Icons.gavel,
    'medication': Icons.medication,
    'work': Icons.work,
    'flight': Icons.flight,
    'restaurant': Icons.restaurant,
    'volunteer_activism': Icons.volunteer_activism,
    'psychology': Icons.psychology,
    'pets': Icons.pets,
    'sports_esports': Icons.sports_esports,
  };

  @override
  void initState() {
    super.initState();
    _clubDataFuture = FirebaseFirestore.instance
        .collection('clubs')
        .doc(widget.kulupId)
        .get();
    _pageController = PageController(initialPage: 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabChange(int index) {
    setState(() => _pageIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _clubDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text("Hata")),
            body: const Center(child: Text("Veri yüklenemedi.")),
          );
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;
        String clubName = data['clubName'] ?? widget.kulupismi;
        String description = data['description'] ?? "Açıklama bulunmuyor.";
        String category = data['category'] ?? "Genel";

        // İKONU ÇEK (Eğer yoksa varsayılan 'groups' ikonunu göster)
        String iconKey = data['icon'] ?? 'groups';
        IconData displayIcon = _clubIcons[iconKey] ?? Icons.groups;

        Map<String, dynamic> theme = data['theme'] ?? {};
        Color primaryColor = hexToColor(theme['primaryColor'] ?? "0xFF00BCD4");
        Color secondaryColor = hexToColor(
          theme['secondaryColor'] ?? "0xFFB2EBF2",
        );

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          bottomNavigationBar: CurvedNavigationBar(
            backgroundColor: const Color(0xFFF5F5F5),
            color: primaryColor,
            animationDuration: const Duration(milliseconds: 300),
            height: 60,
            index: _pageIndex,
            items: const [
              Icon(Icons.info_outline, size: 30, color: Colors.white),
              Icon(Icons.event_available, size: 30, color: Colors.white),
              Icon(Icons.person_outline, size: 30, color: Colors.white),
            ],
            onTap: _onTabChange,
          ),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200.0,
                floating: false,
                pinned: true,
                backgroundColor: primaryColor,
                leading: const BackButton(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    clubName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [primaryColor, primaryColor.withOpacity(0.8)],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          displayIcon, // SEÇİLEN İKON BURADA GÖSTERİLİYOR
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverFillRemaining(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    ClubAboutTab(
                      description: description,
                      category: category,
                      primaryColor: primaryColor,
                      secondaryColor: secondaryColor,
                    ),
                    ClubEventsTab(
                      kulupId: widget.kulupId,
                      primaryColor: primaryColor,
                    ),
                    ClubProfileTab(
                      kulupId: widget.kulupId,
                      kulupIsmi: clubName,
                      primaryColor: primaryColor,
                      onTabChanged: _onTabChange,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
