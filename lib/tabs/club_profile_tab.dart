import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unihub/admin_panel.dart';
import 'package:unihub/widget/info_card.dart';
import 'package:unihub/widget/badge_grid.dart';

class ClubProfileTab extends StatefulWidget {
  final String kulupId;
  final String kulupIsmi;
  final Color primaryColor;
  final Function(int) onTabChanged;

  const ClubProfileTab({
    super.key,
    required this.kulupId,
    required this.kulupIsmi,
    required this.primaryColor,
    required this.onTabChanged,
  });

  @override
  State<ClubProfileTab> createState() => _ClubProfileTabState();
}

class _ClubProfileTabState extends State<ClubProfileTab> {
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

  // --- KULÜPTEN AYRILMA ALGORİTMASI ---
  Future<void> _leaveClub() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Onay Penceresi
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Kulüpten Ayrıl"),
        content: const Text(
          "Bu kulüpten ayrılmak istediğinize emin misiniz?\n\n"
          "Eğer 'Başkan' iseniz, yetkiniz otomatik olarak sıradaki en yetkili üyeye devredilecektir.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Evet, Ayrıl"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final clubRef = FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.kulupId);
      final membersRef = clubRef.collection('members');
      final myDocRef = membersRef.doc(user.uid);

      // Rolümü öğren
      final myDoc = await myDocRef.get();
      if (!myDoc.exists) return;
      final myRole = myDoc.data()?['role'];

      // A) EĞER BAŞKAN DEĞİLSEM -> DİREKT ÇIK
      if (myRole != 'baskan') {
        await myDocRef.delete();
        if (mounted) {
          Navigator.of(context).pop(); // Ekrandan çık
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Kulüpten ayrıldınız.")));
        }
        return;
      }

      // B) EĞER BAŞKANSAM -> DEVRET VE ÇIK
      DocumentSnapshot? newLeader;

      // 1. Aday: Başkan Yardımcıları
      var snapshot = await membersRef
          .where('role', isEqualTo: 'baskan_yardimcisi')
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) newLeader = snapshot.docs.first;

      // 2. Aday: Koordinatörler
      if (newLeader == null) {
        snapshot = await membersRef
            .where('role', isEqualTo: 'koordinator')
            .limit(1)
            .get();
        if (snapshot.docs.isNotEmpty) newLeader = snapshot.docs.first;
      }

      // 3. Aday: Üyeler (Kendim hariç)
      if (newLeader == null) {
        snapshot = await membersRef.where('role', isEqualTo: 'uye').get();
        for (var doc in snapshot.docs) {
          if (doc.id != user.uid) {
            newLeader = doc;
            break;
          }
        }
      }

      if (newLeader != null) {
        // Batch işlemi: Ben silinirim, o başkan olur (Atomik işlem)
        final batch = FirebaseFirestore.instance.batch();
        batch.delete(myDocRef); // Beni sil
        batch.update(newLeader.reference, {'role': 'baskan'}); // Onu başkan yap

        await batch.commit();

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Ayrıldınız. Yeni başkan: ${newLeader['userName'] ?? 'Belirlendi'}",
              ),
            ),
          );
        }
      } else {
        // C) KİMSE YOKSA -> KULÜBÜ SİL
        // (Tek üye bendim ve çıktım)
        await clubRef.delete();
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Kulüp feshedildi (Son üye ayrıldı)."),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
        );
      }
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
            .doc(widget.kulupId)
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
          var roleStyle = _getRoleStyle(role, widget.primaryColor);

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
                          color: widget.primaryColor,
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
                            widget.onTabChanged(1), // Etkinlikler sekmesine git
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.primaryColor,
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

                // Yönetim Paneli Butonu (Sadece Yetkililer)
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
                              kulupismi: widget.kulupIsmi,
                              primaryColor: widget.primaryColor,
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
                    Icon(Icons.military_tech, color: widget.primaryColor),
                    const SizedBox(width: 10),
                    Text(
                      "Rozetlerim",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: widget.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                BadgeGrid(
                  clubId: widget.kulupId,
                  userId: user.uid,
                  themeColor: widget.primaryColor,
                ),

                const SizedBox(height: 40),

                // YENİ: KULÜPTEN AYRILMA BUTONU
                OutlinedButton.icon(
                  onPressed: _leaveClub,
                  icon: const Icon(Icons.exit_to_app, color: Colors.red),
                  label: const Text("Kulüpten Ayrıl"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
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
