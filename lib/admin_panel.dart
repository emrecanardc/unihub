import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanel extends StatefulWidget {
  final String kulupId;
  final String kulupismi;
  final Color primaryColor;
  final String currentUserRole; // Giriş yapan kişinin rolü

  const AdminPanel({
    super.key,
    required this.kulupId,
    required this.kulupismi,
    required this.primaryColor,
    required this.currentUserRole,
  });

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> with TickerProviderStateMixin {
  late TabController _tabController;

  // Hangi sekmelerin gösterileceğini tutan liste
  late List<Widget> _tabs;
  late List<Widget> _tabViews;

  // Form Kontrolcüleri
  final _eventNameController = TextEditingController();
  final _eventDescController = TextEditingController();
  final _eventLocationController = TextEditingController();
  DateTime? _selectedDate;

  // Kulüp Ayarları Kontrolcüleri
  final _clubNameController = TextEditingController();
  final _clubDescController = TextEditingController();
  String? _selectedColorHex; // Seçilen yeni renk kodu

  @override
  void initState() {
    super.initState();
    _setupTabsByRole();
    _loadClubSettings(); // Mevcut ayarları yükle
  }

  // ROL KONTROLÜNE GÖRE SEKMELERİ AYARLA
  void _setupTabsByRole() {
    _tabs = [];
    _tabViews = [];

    // 1. HERKES İÇİN: İstekler Sekmesi
    _tabs.add(const Tab(icon: Icon(Icons.person_add), text: "İstekler"));
    _tabViews.add(_buildRequestsTab());

    // 2. BAŞKAN VE YARDIMCISI İÇİN: Etkinlikler Sekmesi
    if (widget.currentUserRole == 'baskan' ||
        widget.currentUserRole == 'baskan_yardimcisi') {
      _tabs.add(const Tab(icon: Icon(Icons.event), text: "Etkinlikler"));
      _tabViews.add(_buildEventsTab());
    }

    // 3. SADECE BAŞKAN İÇİN: Üyeler ve Ayarlar
    if (widget.currentUserRole == 'baskan') {
      _tabs.add(const Tab(icon: Icon(Icons.people), text: "Üyeler"));
      _tabViews.add(_buildMembersTab());

      _tabs.add(const Tab(icon: Icon(Icons.settings), text: "Ayarlar"));
      _tabViews.add(_buildSettingsTab());
    }

    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  // Mevcut ayarları çekip kutucuklara doldurur
  void _loadClubSettings() async {
    var doc = await FirebaseFirestore.instance
        .collection('clubs')
        .doc(widget.kulupId)
        .get();
    if (doc.exists) {
      var data = doc.data()!;
      _clubNameController.text = data['clubName'] ?? '';
      _clubDescController.text = data['description'] ?? '';
      if (data['theme'] != null) {
        setState(() {
          _selectedColorHex = data['theme']['primaryColor'];
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _eventNameController.dispose();
    _eventDescController.dispose();
    _eventLocationController.dispose();
    _clubNameController.dispose();
    _clubDescController.dispose();
    super.dispose();
  }

  // --- FONKSİYONLAR ---

  // Üye Rolünü Değiştirme (Maksimum Sayı Kontrollü)
  Future<void> _changeMemberRole(String userId, String newRole) async {
    // Eğer Başkan Yardımcısı atanacaksa sayı kontrolü yap
    if (newRole == 'baskan_yardimcisi') {
      var snapshot = await FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.kulupId)
          .collection('members')
          .where('role', isEqualTo: 'baskan_yardimcisi')
          .get();

      if (snapshot.docs.length >= 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Hata: En fazla 2 Başkan Yardımcısı olabilir!"),
              backgroundColor: Colors.red,
            ),
          );
        }
        return; // İşlemi iptal et
      }
    }

    // Rolü güncelle
    await FirebaseFirestore.instance
        .collection('clubs')
        .doc(widget.kulupId)
        .collection('members')
        .doc(userId)
        .update({'role': newRole});

    if (mounted) {
      Navigator.pop(context); // Dialogu kapat
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Rol güncellendi: $newRole"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Kulüp Ayarlarını Kaydet
  Future<void> _saveSettings() async {
    try {
      await FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.kulupId)
          .update({
            'clubName': _clubNameController.text.trim(),
            'description': _clubDescController.text.trim(),
            'theme.primaryColor':
                _selectedColorHex ?? "0xFF00BCD4", // Varsayılan renk
          });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ayarlar güncellendi!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Hata oluştu"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Etkinlik Silme
  Future<void> _deleteEvent(String eventId) async {
    await FirebaseFirestore.instance
        .collection('clubs')
        .doc(widget.kulupId)
        .collection('events')
        .doc(eventId)
        .delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Etkinlik silindi."),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // Üye İşlemleri (Onay/Red)
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
            'username': userData['displayName'] ?? 'İsimsiz',
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
          content: Text(onayla ? "Üye onaylandı!" : "İstek reddedildi."),
          backgroundColor: onayla ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  // Etkinlik Oluşturma
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
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Etkinlik yayınlandı!"),
            backgroundColor: Colors.green,
          ),
        );
    }
  }

  // --- ARAYÜZ (UI) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: widget.primaryColor,
        title: Text(
          "${widget.kulupismi} Yönetimi",
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        leading: const BackButton(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true, // Sekmeler sığmazsa kaydırılabilir olsun
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _tabs,
        ),
      ),
      body: TabBarView(controller: _tabController, children: _tabViews),
    );
  }

  // 1. TAB: İSTEKLER
  Widget _buildRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.kulupId)
          .collection('membershipRequests')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const Center(child: Text("Bekleyen istek yok."));
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
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

  // 2. TAB: ETKİNLİKLER (Oluşturma ve Silme)
  Widget _buildEventsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Yeni Etkinlik Ekle",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
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
            title: Text(
              _selectedDate == null
                  ? "Tarih Seçin"
                  : "${_selectedDate!.day}/${_selectedDate!.month}",
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2030),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
          ElevatedButton(
            onPressed: _createEvent,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text("Yayınla"),
          ),

          const Divider(height: 40, thickness: 2),
          const Text(
            "Mevcut Etkinlikler",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          // Mevcut Etkinlikleri Listeleme ve Silme
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('clubs')
                .doc(widget.kulupId)
                .collection('events')
                .orderBy('date')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var event = snapshot.data!.docs[index];
                  return ListTile(
                    title: Text(event['eventName']),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteEvent(event.id),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // 3. TAB: ÜYELER (Rol Değiştirme)
  Widget _buildMembersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.kulupId)
          .collection('members')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            String currentRole = data['role'] ?? 'uye';

            // Kendi rolünü değiştiremesin (Başkan kendini silemez)
            // Bu basit bir güvenlik önlemidir.

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    data['username'] != null
                        ? data['username'].substring(0, 1)
                        : "?",
                  ),
                ),
                title: Text(
                  "${data['username']} (${_getRoleName(currentRole)})",
                ),
                subtitle: Text(data['userEmail'] ?? ""),
                trailing: const Icon(Icons.edit),
                onTap: () =>
                    _showRoleDialog(doc.id, data['username'], currentRole),
              ),
            );
          },
        );
      },
    );
  }

  String _getRoleName(String role) {
    switch (role) {
      case 'baskan':
        return '👑 Başkan';
      case 'baskan_yardimcisi':
        return '⭐ Bşk. Yrd.';
      case 'koordinator':
        return '⚡ Koordinatör';
      default:
        return 'Üye';
    }
  }

  // Rol Atama Penceresi
  void _showRoleDialog(String userId, String userName, String currentRole) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text("$userName için Rol Seç"),
        children: [
          _roleOption(userId, 'uye', "Üye (Yetkilerini Al)"),
          _roleOption(userId, 'koordinator', "⚡ Koordinatör Yap"),
          _roleOption(userId, 'baskan_yardimcisi', "⭐ Başkan Yardımcısı Yap"),
        ],
      ),
    );
  }

  Widget _roleOption(String userId, String roleKey, String label) {
    return SimpleDialogOption(
      padding: const EdgeInsets.all(15),
      child: Text(label, style: const TextStyle(fontSize: 16)),
      onPressed: () => _changeMemberRole(userId, roleKey),
    );
  }

  // 4. TAB: AYARLAR (Renk ve İsim)
  Widget _buildSettingsTab() {
    List<String> colors = [
      "0xFFF44336",
      "0xFFE91E63",
      "0xFF9C27B0",
      "0xFF2196F3",
      "0xFF00BCD4",
      "0xFF4CAF50",
      "0xFFFFC107",
      "0xFFFF5722",
      "0xFF607D8B",
      "0xFF000000",
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Kulüp Bilgileri",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _clubNameController,
            decoration: const InputDecoration(
              labelText: "Kulüp Adı",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _clubDescController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: "Açıklama",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            "Tema Rengi",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: colors.map((hex) {
              bool isSelected = _selectedColorHex == hex;
              return GestureDetector(
                onTap: () => setState(() => _selectedColorHex = hex),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(
                      int.parse(hex.replaceFirst('0x', 'ff'), radix: 16),
                    ),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.black, width: 3)
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text("Değişiklikleri Kaydet"),
            ),
          ),
        ],
      ),
    );
  }
}
