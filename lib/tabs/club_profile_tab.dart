import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unihub/admin_panel.dart';
import 'package:unihub/widget/info_card.dart'; // 1. Aşamada oluşturduğumuz widget
import 'package:unihub/widget/badge_grid.dart'; // 1. Aşamada oluşturduğumuz widget

class ClubProfileTab extends StatelessWidget {
  final String kulupId;
  final String kulupIsmi;
  final Color primaryColor;
  final Function(int)
  onTabChanged; // "Üye Ol" butonuna basınca sayfayı değiştirmek için

  const ClubProfileTab({
    super.key,
    required this.kulupId,
    required this.kulupIsmi,
    required this.primaryColor,
    required this.onTabChanged,
  });

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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Giriş yapılmamış"));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('clubs')
            .doc(kulupId)
            .collection('members')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          bool isMember = snapshot.hasData && snapshot.data!.exists;
          Map<String, dynamic>? memberData = isMember
              ? snapshot.data!.data() as Map<String, dynamic>
              : null;
          String role = memberData?['role'] ?? 'uye';
          var roleStyle = _getRoleStyle(role, primaryColor);

          return Column(
            children: [
              const SizedBox(height: 20),
              // Profil Resmi ve İkon
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
                                color: (roleStyle['color'] as Color)
                                    .withOpacity(0.5),
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
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(user.email ?? "", style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 30),

              // Üye Değilse Uyarı Kartı
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
                      Icon(
                        Icons.lock_outline,
                        size: 50,
                        color: Colors.grey[400],
                      ),
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
                        onPressed: () =>
                            onTabChanged(1), // Etkinlikler sekmesine git
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
                // Rol Kartı
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

                // Bilgi Kartı (Widget)
                InfoCard(
                  title: "Katılma Tarihi",
                  value: _formatDate(memberData?['joinDate']),
                  icon: Icons.calendar_month,
                  color: Colors.grey,
                ),
                const SizedBox(height: 30),

                // Yönetim Paneli Butonu
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
                              kulupId: kulupId,
                              kulupismi: kulupIsmi,
                              primaryColor: primaryColor,
                              currentUserRole: role,
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

                // Rozetler (Widget)
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
                BadgeGrid(
                  clubId: kulupId,
                  userId: user.uid,
                  themeColor: primaryColor,
                ),
              ],
              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }
}
