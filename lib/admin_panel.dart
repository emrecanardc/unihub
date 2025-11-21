import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:unihub/utils/hex_color.dart';

class AdminPanel extends StatefulWidget {
  final String kulupId;
  final String kulupismi;
  final Color primaryColor;
  final String currentUserRole;

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

  // Form Kontrolcüleri
  final _eventNameController = TextEditingController();
  final _eventDescController = TextEditingController();
  final _eventLocationController = TextEditingController();
  DateTime? _selectedDate;

  final _clubNameController = TextEditingController();
  final _shortNameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _clubDescController = TextEditingController();

  Color _pickerColor = Colors.cyan;
  Color _currentColor = Colors.cyan;
  String _selectedIconKey = 'groups';

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
    _setupTabsByRole();
    _loadClubSettings();
  }

  void _setupTabsByRole() {
    List<Widget> tabs = [];
    List<Widget> tabViews = [];

    tabs.add(const Tab(icon: Icon(Icons.person_add), text: "İstekler"));
    tabViews.add(_buildRequestsTab());

    if (widget.currentUserRole == 'baskan' ||
        widget.currentUserRole == 'baskan_yardimcisi') {
      tabs.add(const Tab(icon: Icon(Icons.event), text: "Etkinlikler"));
      tabViews.add(_buildEventsTab());
    }

    if (widget.currentUserRole == 'baskan') {
      tabs.add(const Tab(icon: Icon(Icons.people), text: "Üyeler"));
      tabViews.add(_buildMembersTab());

      tabs.add(const Tab(icon: Icon(Icons.settings), text: "Ayarlar"));
      tabViews.add(_buildSettingsTab());
    }

    _tabController = TabController(length: tabs.length, vsync: this);
  }

  void _loadClubSettings() async {
    var doc = await FirebaseFirestore.instance
        .collection('clubs')
        .doc(widget.kulupId)
        .get();
    if (doc.exists && mounted) {
      var data = doc.data()!;
      setState(() {
        _clubNameController.text = data['clubName'] ?? '';
        _shortNameController.text = data['shortName'] ?? '';
        _categoryController.text = data['category'] ?? '';
        _clubDescController.text = data['description'] ?? '';
        _selectedIconKey = data['icon'] ?? 'groups';
        if (data['theme'] != null && data['theme']['primaryColor'] != null) {
          _currentColor = hexToColor(data['theme']['primaryColor']);
          _pickerColor = _currentColor;
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _eventNameController.dispose();
    _eventDescController.dispose();
    _eventLocationController.dispose();
    _clubNameController.dispose();
    _shortNameController.dispose();
    _categoryController.dispose();
    _clubDescController.dispose();
    super.dispose();
  }

  // --- RENK VE STİL FONKSİYONLARI (YENİLENDİ) ---

  // Rol Önceliği (Sıralama için)
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

  // Rol Stili (Renk Geçişleri ve İkonlar)
  Map<String, dynamic> _getRoleStyle(String role) {
    switch (role) {
      case 'baskan':
        return {
          'gradient': const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFF8C00)], // Altın -> Turuncu
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'icon': Icons.emoji_events,
          'label': 'Kulüp Başkanı',
        };
      case 'baskan_yardimcisi':
        return {
          'gradient': const LinearGradient(
            colors: [Color(0xFFE0E0E0), Color(0xFF9E9E9E)], // Gümüş -> Koyu Gri
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'icon': Icons.star,
          'label': 'Başkan Yardımcısı',
        };
      case 'koordinator':
        return {
          'gradient': const LinearGradient(
            colors: [Color(0xFFFFCC80), Color(0xFF8D6E63)], // Bronz -> Kahve
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'icon': Icons.bolt,
          'label': 'Koordinatör',
        };
      default:
        return {
          'gradient': LinearGradient(
            colors: [
              Colors.blueGrey.shade300,
              Colors.blueGrey.shade500,
            ], // Mavi/Gri
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'icon': Icons.person,
          'label': 'Üye',
        };
    }
  }

  // --- DİĞER FONKSİYONLAR ---
  String _colorToHex(Color color) {
    return '0xFF${color.value.toRadixString(16).padLeft(8, '0').toUpperCase().substring(2)}';
  }

  Future<void> _saveSettings() async {
    try {
      Color secondaryColor = Color.alphaBlend(
        Colors.white.withOpacity(0.6),
        _currentColor,
      );
      await FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.kulupId)
          .update({
            'clubName': _clubNameController.text.trim(),
            'shortName': _shortNameController.text.trim().toUpperCase(),
            'category': _categoryController.text.trim(),
            'description': _clubDescController.text.trim(),
            'icon': _selectedIconKey,
            'logoUrl': FieldValue.delete(),
            'theme': {
              'primaryColor': _colorToHex(_currentColor),
              'secondaryColor': _colorToHex(secondaryColor),
            },
          });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ayarlar başarıyla güncellendi!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _showColorPickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kulüp Rengini Seç'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _pickerColor,
            onColorChanged: (color) => setState(() => _pickerColor = color),
            enableAlpha: false,
            displayThumbColor: true,
            paletteType: PaletteType.hsvWithHue,
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('Tamam'),
            onPressed: () {
              setState(() => _currentColor = _pickerColor);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
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
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Başkanlık $targetUserName'e devredildi."),
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

  Future<void> _changeMemberRole(String userId, String newRole) async {
    await FirebaseFirestore.instance
        .collection('clubs')
        .doc(widget.kulupId)
        .collection('members')
        .doc(userId)
        .update({'role': newRole});
    if (mounted) Navigator.pop(context);
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

  Future<void> _deleteEvent(String eventId) async {
    await FirebaseFirestore.instance
        .collection('clubs')
        .doc(widget.kulupId)
        .collection('events')
        .doc(eventId)
        .delete();
  }

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
  }

  // --- UI BUILD ---
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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _getTabs(),
        ),
      ),
      body: TabBarView(controller: _tabController, children: _getTabViews()),
    );
  }

  List<Widget> _getTabs() {
    List<Widget> tabs = [
      const Tab(icon: Icon(Icons.person_add), text: "İstekler"),
    ];
    if (widget.currentUserRole != 'uye')
      tabs.add(const Tab(icon: Icon(Icons.event), text: "Etkinlikler"));
    if (widget.currentUserRole == 'baskan') {
      tabs.add(const Tab(icon: Icon(Icons.people), text: "Üyeler"));
      tabs.add(const Tab(icon: Icon(Icons.settings), text: "Ayarlar"));
    }
    return tabs;
  }

  List<Widget> _getTabViews() {
    List<Widget> views = [_buildRequestsTab()];
    if (widget.currentUserRole != 'uye') views.add(_buildEventsTab());
    if (widget.currentUserRole == 'baskan') {
      views.add(_buildMembersTab());
      views.add(_buildSettingsTab());
    }
    return views;
  }

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

  Widget _buildEventsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
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
          ElevatedButton(onPressed: _createEvent, child: const Text("Yayınla")),
          const Divider(),
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

  // --- YENİLENEN TASARIM: ÜYELER SEKMESİ ---
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

        var docs = snapshot.data!.docs;
        // Sıralama: Başkan -> Yardımcı -> Koordinatör -> Üye
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
                width: double.infinity,
                height: 70, // Sabit, şık bir yükseklik
                decoration: BoxDecoration(
                  gradient: style['gradient'], // Rol'e özel renk geçişi
                  borderRadius: BorderRadius.circular(
                    30,
                  ), // Yuvarlak "Chip" tasarımı (Resimdeki gibi)
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
                    // Sol İkon
                    Icon(style['icon'], color: Colors.white, size: 28),
                    const SizedBox(width: 20),
                    // İsim ve Görev
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
                            style['label'], // Rol ismi (Örn: Kulüp Başkanı)
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Düzenle İkonu (Sağda)
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

  Widget _buildSettingsTab() {
    /* ...Eski kodun aynısı... */
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Kulüp Kimliği"),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _clubNameController,
                    decoration: const InputDecoration(
                      labelText: "Kulüp Adı",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _shortNameController,
                          maxLength: 4,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: "Kısaltma",
                            border: OutlineInputBorder(),
                            counterText: "",
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _categoryController,
                          decoration: const InputDecoration(
                            labelText: "Kategori",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle("Görsel Kimlik"),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Kulüp İkonu",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: _clubIcons.length,
                      itemBuilder: (context, index) {
                        String key = _clubIcons.keys.elementAt(index);
                        IconData icon = _clubIcons.values.elementAt(index);
                        bool isSelected = _selectedIconKey == key;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedIconKey = key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _currentColor.withOpacity(0.2)
                                  : Colors.transparent,
                              border: isSelected
                                  ? Border.all(color: _currentColor, width: 2)
                                  : Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              icon,
                              color: isSelected ? _currentColor : Colors.grey,
                              size: 28,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: _currentColor,
                      radius: 20,
                    ),
                    title: const Text(
                      "Tema Rengi",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("Renk kodu: ${_colorToHex(_currentColor)}"),
                    trailing: ElevatedButton(
                      onPressed: _showColorPickerDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Değiştir"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text("Tüm Değişiklikleri Kaydet"),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}
