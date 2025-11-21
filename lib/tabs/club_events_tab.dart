import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unihub/widget/event_list_tile.dart';

class ClubEventsTab extends StatefulWidget {
  final String kulupId;
  final Color primaryColor;

  const ClubEventsTab({
    super.key,
    required this.kulupId,
    required this.primaryColor,
  });

  @override
  State<ClubEventsTab> createState() => _ClubEventsTabState();
}

class _ClubEventsTabState extends State<ClubEventsTab> {
  // Rol Tasarım Yardımcısı (Admin Panelindeki ile aynı mantık)
  Map<String, dynamic> _getRoleStyle(String role) {
    switch (role) {
      case 'baskan':
        return {
          'gradient': const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFF8C00)], // Altın
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'icon': Icons.emoji_events,
          'label': 'Kulüp Başkanı',
          'message': 'Kulübü yönetmeye hazır mısın?',
        };
      case 'baskan_yardimcisi':
        return {
          'gradient': const LinearGradient(
            colors: [Color(0xFFE0E0E0), Color(0xFF9E9E9E)], // Gümüş
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'icon': Icons.star,
          'label': 'Başkan Yardımcısı',
          'message': 'Yönetim ekibinin kilit ismisin.',
        };
      case 'koordinator':
        return {
          'gradient': const LinearGradient(
            colors: [Color(0xFFFFCC80), Color(0xFF8D6E63)], // Bronz
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'icon': Icons.bolt,
          'label': 'Koordinatör',
          'message': 'Operasyonlar senden sorulur.',
        };
      default:
        return {
          // Üyeler için kulübün kendi rengini kullanan bir gradient
          'gradient': LinearGradient(
            colors: [widget.primaryColor, widget.primaryColor.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'icon': Icons.verified,
          'label': 'Kulüp Üyesi',
          'message': 'Etkinliklere katıl ve aktif ol!',
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
        );
      }
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
    if (user == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('clubs')
            .doc(widget.kulupId)
            .collection('members')
            .doc(user.uid)
            .snapshots(),
        builder: (context, memberSnapshot) {
          bool isMember = memberSnapshot.hasData && memberSnapshot.data!.exists;
          String? role;

          // Eğer üyeyse, rol bilgisini al
          if (isMember) {
            var data = memberSnapshot.data!.data() as Map<String, dynamic>;
            role = data['role'] ?? 'uye';
          }

          if (isMember) {
            return _buildContent(
              isMember: true,
              hasPendingRequest: false,
              role: role,
            );
          }

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
              return _buildContent(
                isMember: false,
                hasPendingRequest: hasPendingRequest,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildContent({
    required bool isMember,
    required bool hasPendingRequest,
    String? role,
  }) {
    // Rol stilini belirle (Eğer üye değilse varsayılan null)
    var roleStyle = isMember ? _getRoleStyle(role!) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- DURUM KARTI (GÜNCELLENDİ) ---
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            // Üyeyse özel gradient, değilse standart kulüp rengi
            gradient: isMember
                ? roleStyle!['gradient']
                : LinearGradient(
                    colors: [
                      widget.primaryColor,
                      widget.primaryColor.withOpacity(0.7),
                    ],
                  ),
            borderRadius: BorderRadius.circular(20), // Daha yuvarlak köşeler
            boxShadow: [
              BoxShadow(
                color:
                    (isMember
                            ? (roleStyle!['gradient'] as LinearGradient)
                                  .colors
                                  .first
                            : widget.primaryColor)
                        .withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              if (isMember) ...[
                // ROL İKONU VE İSMİ
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        roleStyle!['icon'],
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Flexible(
                      child: Text(
                        roleStyle['label'], // "Kulüp Başkanı" yazısı
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // ALT MESAJ
                Text(
                  roleStyle['message'], // "Kulübü yönetmeye hazır mısın?" vb.
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
                  "Yöneticilerden onay bekleniyor...",
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
                const Icon(
                  Icons.waving_hand,
                  color: Colors.white,
                  size: 40,
                ), // Karşılama ikonu
                const SizedBox(height: 10),
                const Text(
                  "Aramıza Katıl!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Bu topluluğun bir parçası olmak için hemen başvur.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: _uyeOlIstegiGonder,
                  icon: const Icon(Icons.check_circle, color: Colors.black87),
                  label: const Text("Üye Olma İsteği Gönder"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
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

        // Etkinlikler Başlığı
        Row(
          children: [
            Icon(Icons.event, color: widget.primaryColor),
            const SizedBox(width: 10),
            Text(
              "Yaklaşan Etkinlikler",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: widget.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),

        _buildEventsList(),

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildEventsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.kulupId)
          .collection('events')
          .orderBy('date') // Tarihe göre sıralama eklendi
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(30),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.event_busy, color: Colors.grey.shade300, size: 50),
                const SizedBox(height: 10),
                Text(
                  "Planlanmış etkinlik yok.",
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }
        return Column(
          children: snapshot.data!.docs.map((doc) {
            var event = doc.data() as Map<String, dynamic>;
            return EventListTile(
              title: event['eventName'] ?? 'Etkinlik',
              description: event['description'] ?? '',
              themeColor: widget.primaryColor,
            );
          }).toList(),
        );
      },
    );
  }
}
