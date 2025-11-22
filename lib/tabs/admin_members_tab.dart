import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminMembersTab extends StatefulWidget {
  final String kulupId;
  final String currentUserRole;

  const AdminMembersTab({
    super.key,
    required this.kulupId,
    required this.currentUserRole,
  });

  @override
  State<AdminMembersTab> createState() => _AdminMembersTabState();
}

class _AdminMembersTabState extends State<AdminMembersTab> {
  int _getRolePriority(String? role) {
    switch (role) {
      case 'baskan':
        return 0;
      case 'baskan_yardimcisi':
        return 1;
      case 'koordinator':
        return 2;
      default:
        return 3;
    }
  }

  Map<String, dynamic> _getRoleStyle(String role) {
    switch (role) {
      case 'baskan':
        return {
          'gradient': const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
          ),
          'icon': Icons.emoji_events,
          'label': 'Başkan',
        };
      case 'baskan_yardimcisi':
        return {
          'gradient': const LinearGradient(
            colors: [Color(0xFFE0E0E0), Color(0xFF9E9E9E)],
          ),
          'icon': Icons.star,
          'label': 'Başkan Yrd.',
        };
      case 'koordinator':
        return {
          'gradient': const LinearGradient(
            colors: [Color(0xFFFFCC80), Color(0xFF8D6E63)],
          ),
          'icon': Icons.bolt,
          'label': 'Koordinatör',
        };
      default:
        return {
          'gradient': LinearGradient(
            colors: [Colors.blueGrey.shade300, Colors.blueGrey.shade500],
          ),
          'icon': Icons.person,
          'label': 'Üye',
        };
    }
  }

  Future<void> _changeMemberRole(String userId, String newRole) async {
    await FirebaseFirestore.instance
        .collection('clubs')
        .doc(widget.kulupId)
        .collection('members')
        .doc(userId)
        .update({'role': newRole});
    if (mounted) Navigator.pop(context);
  }

  Future<void> _transferPresidency(
    String targetUserId,
    String targetUserName,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Başkanlığı Devret"),
        content: Text(
          "Dikkat! Başkanlığı '$targetUserName' adlı üyeye devretmek üzeresiniz.\n\nOnaylıyor musunuz?",
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
            child: const Text("Evet, Devret"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        var targetRef = FirebaseFirestore.instance
            .collection('clubs')
            .doc(widget.kulupId)
            .collection('members')
            .doc(targetUserId);
        batch.update(targetRef, {'role': 'baskan'});
        var myRef = FirebaseFirestore.instance
            .collection('clubs')
            .doc(widget.kulupId)
            .collection('members')
            .doc(currentUser.uid);
        batch.update(myRef, {'role': 'uye'});
        await batch.commit();
        if (mounted) {
          Navigator.pop(context);
          Navigator.pop(context); // Panelden çık
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Başkanlık devredildi."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showRoleDialog(String userId, String userName, String currentRole) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == currentUserId) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("İşlem Engellendi"),
          content: const Text("Kendi rolünüzü değiştiremezsiniz."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tamam"),
            ),
          ],
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text("$userName için Rol Seç"),
        children: [
          SimpleDialogOption(
            onPressed: () => _changeMemberRole(userId, 'uye'),
            child: const Text("Üye Yap"),
          ),
          SimpleDialogOption(
            onPressed: () => _changeMemberRole(userId, 'koordinator'),
            child: const Text("Koordinatör Yap"),
          ),
          SimpleDialogOption(
            onPressed: () => _changeMemberRole(userId, 'baskan_yardimcisi'),
            child: const Text("Başkan Yardımcısı Yap"),
          ),
          if (widget.currentUserRole == 'baskan') ...[
            const Divider(),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _transferPresidency(userId, userName);
              },
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Başkanlığı Devret",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.kulupId)
          .collection('members')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        var docs = snapshot.data!.docs;
        docs.sort((a, b) {
          var roleA = (a.data() as Map<String, dynamic>)['role'];
          var roleB = (b.data() as Map<String, dynamic>)['role'];
          return _getRolePriority(roleA).compareTo(_getRolePriority(roleB));
        });

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            var doc = docs[index];
            var data = doc.data() as Map<String, dynamic>;
            String name = data['userName'] ?? data['username'] ?? "?";
            String role = data['role'] ?? 'uye';
            var style = _getRoleStyle(role);

            return GestureDetector(
              onTap: () => _showRoleDialog(doc.id, name, role),
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  gradient: style['gradient'],
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    Icon(style['icon'], color: Colors.white, size: 28),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            style['label'],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
