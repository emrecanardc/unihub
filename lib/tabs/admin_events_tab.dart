import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminEventsTab extends StatefulWidget {
  final String kulupId;

  const AdminEventsTab({super.key, required this.kulupId});

  @override
  State<AdminEventsTab> createState() => _AdminEventsTabState();
}

class _AdminEventsTabState extends State<AdminEventsTab> {
  final _eventNameController = TextEditingController();
  final _eventDescController = TextEditingController();
  final _eventLocationController = TextEditingController();
  DateTime? _selectedDate;

  Future<void> _createEvent() async {
    if (_eventNameController.text.isNotEmpty && _selectedDate != null) {
      await FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.kulupId)
          .collection('events')
          .add({
            'eventName': _eventNameController.text.trim(),
            'description': _eventDescController.text.trim(),
            'location': _eventLocationController.text.trim(),
            'date': Timestamp.fromDate(_selectedDate!),
            'createdAt': FieldValue.serverTimestamp(),
          });
      _eventNameController.clear();
      _eventDescController.clear();
      _eventLocationController.clear();
      setState(() => _selectedDate = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Etkinlik yayınlandı!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    await FirebaseFirestore.instance
        .collection('clubs')
        .doc(widget.kulupId)
        .collection('events')
        .doc(eventId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            "Yeni Etkinlik Oluştur",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _eventNameController,
            decoration: const InputDecoration(
              labelText: "Etkinlik Adı",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _eventDescController,
            decoration: const InputDecoration(
              labelText: "Açıklama",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _eventLocationController,
            decoration: const InputDecoration(
              labelText: "Konum",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _selectedDate == null
                  ? "Tarih Seçin"
                  : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2030),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _createEvent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
              ),
              child: const Text("Yayınla"),
            ),
          ),

          const Divider(height: 40, thickness: 2),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('clubs')
                .doc(widget.kulupId)
                .collection('events')
                .orderBy('date', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              final now = DateTime.now();
              final allDocs = snapshot.data!.docs;

              final upcomingEvents = allDocs.where((doc) {
                final Timestamp? ts =
                    (doc.data() as Map<String, dynamic>)['date'];
                return ts != null && ts.toDate().isAfter(now);
              }).toList();

              final pastEvents = allDocs.where((doc) {
                final Timestamp? ts =
                    (doc.data() as Map<String, dynamic>)['date'];
                return ts != null && ts.toDate().isBefore(now);
              }).toList();

              final reversedPastEvents = pastEvents.reversed.toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Yaklaşan Etkinlikler",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (upcomingEvents.isEmpty)
                    const Text(
                      "Yaklaşan etkinlik yok.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ...upcomingEvents.map((doc) => _buildEventCard(doc, false)),

                  const SizedBox(height: 30),

                  const Text(
                    "Geçmiş Etkinlikler",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (reversedPastEvents.isEmpty)
                    const Text(
                      "Geçmiş etkinlik yok.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ...reversedPastEvents.map(
                    (doc) => _buildEventCard(doc, true),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(DocumentSnapshot doc, bool isPast) {
    var event = doc.data() as Map<String, dynamic>;
    return Card(
      color: isPast ? Colors.grey.shade100 : Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(
          isPast ? Icons.history : Icons.event,
          color: isPast ? Colors.grey : Colors.green,
        ),
        title: Text(
          event['eventName'] ?? '?',
          style: TextStyle(color: isPast ? Colors.grey : Colors.black87),
        ),
        subtitle: Text(
          event['date'] != null
              ? (event['date'] as Timestamp).toDate().toString().split(' ')[0]
              : '',
          style: TextStyle(color: isPast ? Colors.grey : Colors.black54),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteEvent(doc.id),
        ),
      ),
    );
  }
}
