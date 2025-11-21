import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:unihub/login.dart';
import 'package:unihub/admin_panel.dart';

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

  Color _hexToColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', '').replaceFirst('0x', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.cyan;
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "Tarih Yok";
    DateTime date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year}";
  }

  Map<String, dynamic> _getRoleStyle(String role, Color defaultColor) {
    switch (role) {
      case 'baskan':
        return {
          'color': const Color(0xFFFFD700),
          'icon': Icons.emoji_events,
          'label': 'Kulüp Başkanı',
          'gradient': [const Color(0xFFFFD700), const Color(0xFFFFA500)],
        };
      case 'baskan_yardimcisi':
        return {
          'color': const Color(0xFFC0C0C0),
          'icon': Icons.star,
          'label': 'Başkan Yardımcısı',
          'gradient': [const Color(0xFFE0E0E0), const Color(0xFF9E9E9E)],
        };
      case 'koordinator':
        return {
          'color': const Color(0xFFCD7F32),
          'icon': Icons.bolt,
          'label': 'Koordinatör',
          'gradient': [const Color(0xFFFFCC80), const Color(0xFF8D6E63)],
        };
      default:
        return {
          'color': defaultColor,
          'icon': Icons.person,
          'label': 'Üye',
          'gradient': [defaultColor.withOpacity(0.8), defaultColor],
        };
    }
  }

  Future<void> _uyeOlIstegiGonder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.kulupId)
          .collection('membershipRequests')
          .doc(user.uid)
          .set({
            'userId': user.uid,
            'email': user.email,
            'displayName': user.displayName,
            'requestDate': FieldValue.serverTimestamp(),
            'status': 'pending',
          });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
        );
    }
  }

  Future<void> _istegiGeriCek() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.kulupId)
          .collection('membershipRequests')
          .doc(user.uid)
          .delete();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
        );
    }
  }

  Future<void> _cikisYap() async {
    await FirebaseAuth.instance.signOut();
    if (mounted)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const girisEkrani()),
        (route) => false,
      );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _clubDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists)
          return Scaffold(
            appBar: AppBar(title: const Text("Hata")),
            body: const Center(child: Text("Veri yüklenemedi.")),
          );

        var data = snapshot.data!.data() as Map<String, dynamic>;
        String clubName = data['clubName'] ?? widget.kulupismi;
        String description = data['description'] ?? "Açıklama bulunmuyor.";
        String category = data['category'] ?? "Genel";
        String? logoUrl = data['logoUrl'];
        Map<String, dynamic> theme = data['theme'] ?? {};
        Color primaryColor = _hexToColor(theme['primaryColor'] ?? "0xFF00BCD4");
        Color secondaryColor = _hexToColor(
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
            onTap: (index) {
              setState(() => _pageIndex = index);
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180.0,
                floating: false,
                pinned: true,
                backgroundColor: primaryColor,
                leading: const BackButton(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    clubName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
                    ),
                  ),
                  background: Container(
                    color: primaryColor,
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: logoUrl != null && logoUrl.isNotEmpty
                          ? Image.asset(
                              "assets/logos/$logoUrl",
                              fit: BoxFit.contain,
                              errorBuilder: (c, e, s) => const Icon(
                                Icons.groups,
                                size: 80,
                                color: Colors.white54,
                              ),
                            )
                          : const Icon(
                              Icons.groups,
                              size: 80,
                              color: Colors.white54,
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
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildAboutContent(
                        description,
                        category,
                        primaryColor,
                        secondaryColor,
                      ),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildEventsContent(primaryColor, secondaryColor),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildProfileContent(primaryColor, secondaryColor),
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

  Widget _buildEventsContent(Color primaryColor, Color secondaryColor) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.kulupId)
          .collection('members')
          .doc(user.uid)
          .snapshots(),
      builder: (context, memberSnapshot) {
        bool isMember = memberSnapshot.hasData && memberSnapshot.data!.exists;
        if (isMember)
          return _buildEventsListWithStatus(
            primaryColor,
            isMember: true,
            hasPendingRequest: false,
          );
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('clubs')
              .doc(widget.kulupId)
              .collection('membershipRequests')
              .doc(user.uid)
              .snapshots(),
          builder: (context, requestSnapshot) {
            bool hasPendingRequest =
                requestSnapshot.hasData && requestSnapshot.data!.exists;
            return _buildEventsListWithStatus(
              primaryColor,
              isMember: false,
              hasPendingRequest: hasPendingRequest,
            );
          },
        );
      },
    );
  }

  Widget _buildEventsListWithStatus(
    Color primaryColor, {
    required bool isMember,
    required bool hasPendingRequest,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.7)],
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              if (isMember) ...[
                const Icon(Icons.verified, color: Colors.white, size: 40),
                const SizedBox(height: 10),
                const Text(
                  "Bu Kulübün Üyesisiniz!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else if (hasPendingRequest) ...[
                const Icon(Icons.hourglass_top, color: Colors.white, size: 40),
                const SizedBox(height: 10),
                const Text(
                  "Üyelik İsteği Gönderildi",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Onay bekleniyor...",
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: _istegiGeriCek,
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text("İsteği Geri Çek"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ] else ...[
                const Text(
                  "Bu topluluğun bir parçası ol!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: _uyeOlIstegiGonder,
                  icon: const Icon(Icons.check_circle, color: Colors.black87),
                  label: const Text("Üye Olma İsteği Gönder"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 30),
        Text(
          "Yaklaşan Etkinlikler",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 15),
        _buildEventsList(widget.kulupId, primaryColor),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildProfileContent(Color primaryColor, Color secondaryColor) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Giriş yapılmamış"));
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.kulupId)
          .collection('members')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        bool isMember = snapshot.hasData && snapshot.data!.exists;
        Map<String, dynamic>? memberData = isMember
            ? snapshot.data!.data() as Map<String, dynamic>
            : null;
        String role = memberData?['role'] ?? 'uye';
        var roleStyle = _getRoleStyle(role, primaryColor);

        return Column(
          children: [
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isMember
                          ? roleStyle['gradient']
                          : [Colors.grey, Colors.grey.shade300],
                    ),
                    boxShadow: isMember
                        ? [
                            BoxShadow(
                              color: (roleStyle['color'] as Color).withOpacity(
                                0.5,
                              ),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: Text(
                      user.displayName?.substring(0, 1).toUpperCase() ?? "U",
                      style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
                if (isMember)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: roleStyle['color'],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      roleStyle['icon'],
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              user.displayName ?? "İsimsiz Kullanıcı",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(user.email ?? "", style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 30),
            if (!isMember)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.lock_outline, size: 50, color: Colors.grey[400]),
                    const SizedBox(height: 10),
                    const Text(
                      "Henüz Üye Değilsiniz",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Etkinliklere katılmak için üye olun.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _pageIndex = 1);
                        _pageController.animateToPage(
                          1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Üyelik Sayfasına Git"),
                    ),
                  ],
                ),
              ),
            if (isMember) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: roleStyle['gradient']),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: (roleStyle['color'] as Color).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(roleStyle['icon'], color: Colors.white, size: 30),
                    const SizedBox(width: 10),
                    Text(
                      roleStyle['label'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              _buildInfoCard(
                title: "Katılma Tarihi",
                value: _formatDate(memberData?['joinDate']),
                icon: Icons.calendar_month,
                color: Colors.grey,
              ),
              const SizedBox(height: 30),

              // --- YÖNETİM PANELİ BUTONU (DÜZELTİLDİ) ---
              if (role == 'baskan' ||
                  role == 'baskan_yardimcisi' ||
                  role == 'koordinator')
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminPanel(
                            kulupId: widget.kulupId,
                            kulupismi: widget.kulupismi,
                            primaryColor: primaryColor,
                            currentUserRole: role, // ARTIK EKSİK DEĞİL!
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text("Kulüp Yönetim Paneli"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),

              // -----------------------------------------
              Row(
                children: [
                  Icon(Icons.military_tech, color: primaryColor),
                  const SizedBox(width: 10),
                  Text(
                    "Rozetlerim",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _buildBadgesGrid(user.uid, primaryColor),
            ],
            const SizedBox(height: 100),
          ],
        );
      },
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesGrid(String userId, Color themeColor) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.kulupId)
          .collection('members')
          .doc(userId)
          .collection('badges')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 40,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 5),
                const Text(
                  "Henüz kazanılmış rozet yok.",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var badge =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.star, color: themeColor, size: 30),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    badge['badgeName'] ?? 'Rozet',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAboutContent(
    String description,
    String category,
    Color primaryColor,
    Color secondaryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Kulüp Hakkında",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 10),
        Chip(
          label: Text(category),
          backgroundColor: secondaryColor.withOpacity(0.5),
          avatar: Icon(Icons.category, size: 18, color: primaryColor),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildEventsList(String kulupId, Color themeColor) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clubs')
          .doc(kulupId)
          .collection('events')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Row(
              children: [
                Icon(Icons.event_busy, color: Colors.grey),
                SizedBox(width: 10),
                Text("Planlanmış etkinlik yok."),
              ],
            ),
          );
        return Column(
          children: snapshot.data!.docs.map((doc) {
            var event = doc.data() as Map<String, dynamic>;
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.calendar_month, color: themeColor),
                ),
                title: Text(
                  event['eventName'] ?? 'Etkinlik',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  event['description'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
