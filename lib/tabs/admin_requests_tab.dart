import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRequestsTab extends StatefulWidget {
  final String kulupId;

  const AdminRequestsTab({super.key, required this.kulupId});

  @override
  State<AdminRequestsTab> createState() => _AdminRequestsTabState();
}

class _AdminRequestsTabState extends State<AdminRequestsTab> {
  Future<void> _uyeIslemi(
    String userId,
    Map<String, dynamic>? userData,
    bool onayla,
  ) async {
    if (onayla && userData != null) {
      await FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.kulupId)
          .collection('members')
          .doc(userId)
          .set({
            'userName': userData['displayName'] ?? 'İsimsiz',
            'userEmail': userData['email'] ?? '',
            'role': 'uye',
            'joinDate': FieldValue.serverTimestamp(),
          });
    }
    await FirebaseFirestore.instance
        .collection('clubs')
        .doc(widget.kulupId)
        .collection('membershipRequests')
        .doc(userId)
        .delete();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(onayla ? "İstek onaylandı!" : "İstek reddedildi."),
          backgroundColor: onayla ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.kulupId)
          .collection('membershipRequests')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "Bekleyen istek yok.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(data['displayName'] ?? "İsimsiz"),
                subtitle: Text(data['email'] ?? ""),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _uyeIslemi(doc.id, null, false),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _uyeIslemi(doc.id, data, true),
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
