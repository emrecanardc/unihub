import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unihub/admin_panel.dart'; // Mevcut Admin Paneli
import 'package:unihub/utils/hex_color.dart';

class WebAdminPanel extends StatefulWidget {
  const WebAdminPanel({super.key});

  @override
  State<WebAdminPanel> createState() => _WebAdminPanelState();
}

class _WebAdminPanelState extends State<WebAdminPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("UniHub Super Admin (Web) 🚀"),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(icon: Icon(Icons.store), text: "Sponsor Yönetimi"),
            Tab(icon: Icon(Icons.add_business), text: "Kulüp Oluştur"),
            Tab(
              icon: Icon(Icons.admin_panel_settings),
              text: "Tüm Kulüpleri Yönet",
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [SponsorManager(), ClubCreator(), AllClubsManager()],
      ),
    );
  }
}

// --- 1. SPONSOR YÖNETİCİSİ ---
class SponsorManager extends StatefulWidget {
  const SponsorManager({super.key});
  @override
  State<SponsorManager> createState() => _SponsorManagerState();
}

class _SponsorManagerState extends State<SponsorManager> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _urlController = TextEditingController();

  Future<void> _addSponsor() async {
    if (_nameController.text.isEmpty || _urlController.text.isEmpty) return;
    await FirebaseFirestore.instance.collection('app_sponsors').add({
      'name': _nameController.text.trim(),
      'description': _descController.text.trim(),
      'imageUrl': _urlController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    _nameController.clear();
    _descController.clear();
    _urlController.clear();
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Sponsor Eklendi!")));
  }

  Future<void> _deleteSponsor(String id) async {
    await FirebaseFirestore.instance
        .collection('app_sponsors')
        .doc(id)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.grey[50],
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                const Text(
                  "Sponsor Ekle",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Firma Adı",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: "Kampanya Metni",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: "Resim URL",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _addSponsor,
                  icon: const Icon(Icons.add),
                  label: const Text("Yayınla"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('app_sponsors')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  var data = doc.data() as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      leading: Image.network(
                        data['imageUrl'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const Icon(Icons.error),
                      ),
                      title: Text(data['name']),
                      subtitle: Text(data['description'] ?? ""),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteSponsor(doc.id),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// --- 2. KULÜP OLUŞTURUCU (GÜNCELLENDİ: Üniversite Seçimi) ---
class ClubCreator extends StatefulWidget {
  const ClubCreator({super.key});
  @override
  State<ClubCreator> createState() => _ClubCreatorState();
}

class _ClubCreatorState extends State<ClubCreator> {
  final _nameController = TextEditingController();
  final _shortNameController = TextEditingController();
  final _descController = TextEditingController();
  final _categoryController = TextEditingController();

  // Üniversite Seçimi
  String _selectedUni = "ESOGU";
  final List<String> _universities = ["ESOGU", "Anadolu", "ESTÜ"];

  Future<void> _createClub() async {
    if (_nameController.text.isEmpty) return;

    await FirebaseFirestore.instance.collection('clubs').add({
      'clubName': _nameController.text.trim(),
      'shortName': _shortNameController.text.trim().toUpperCase(),
      'description': _descController.text.trim(),
      'category': _categoryController.text.trim(),
      'university': _selectedUni, // YENİ ALAN: Seçilen üniversite kaydediliyor
      'icon': 'groups',
      'theme': {'primaryColor': '0xFF00BCD4', 'secondaryColor': '0xFFB2EBF2'},
      'createdAt': FieldValue.serverTimestamp(),
    });

    _nameController.clear();
    _shortNameController.clear();
    _descController.clear();
    _categoryController.clear();
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Kulüp Oluşturuldu!")));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const Text(
              "Yeni Kulüp Oluştur",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // YENİ: Üniversite Seçim Kutusu
            DropdownButtonFormField<String>(
              value: _selectedUni,
              decoration: const InputDecoration(
                labelText: "Üniversite",
                border: OutlineInputBorder(),
              ),
              items: _universities
                  .map((uni) => DropdownMenuItem(value: uni, child: Text(uni)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedUni = val!),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Kulüp Adı",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _shortNameController,
                    decoration: const InputDecoration(
                      labelText: "Kısaltma (GİK)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
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
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Açıklama",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _createClub,
                icon: const Icon(Icons.add_circle),
                label: const Text("Sisteme Ekle"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 3. TÜM KULÜPLERİ YÖNET (Aynı Kalıyor) ---
class AllClubsManager extends StatelessWidget {
  const AllClubsManager({super.key});

  // Kulüp Silme Fonksiyonu (Kapsamlı Silme)
  Future<void> _deleteCollection(CollectionReference collection) async {
    try {
      var snapshots = await collection.get();
      for (var doc in snapshots.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint("Hata: $e");
    }
  }

  Future<void> _deleteClub(BuildContext context, String clubId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("⚠️ KESİN SİLME"),
        content: const Text(
          "Bu işlem geri alınamaz. Kulüp ve tüm verileri silinecek.",
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
            child: const Text("SİL"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _deleteCollection(
          FirebaseFirestore.instance
              .collection('clubs')
              .doc(clubId)
              .collection('members'),
        );
        await _deleteCollection(
          FirebaseFirestore.instance
              .collection('clubs')
              .doc(clubId)
              .collection('events'),
        );
        await _deleteCollection(
          FirebaseFirestore.instance
              .collection('clubs')
              .doc(clubId)
              .collection('membershipRequests'),
        );
        await FirebaseFirestore.instance
            .collection('clubs')
            .doc(clubId)
            .delete();
        if (context.mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Kulüp silindi."),
              backgroundColor: Colors.green,
            ),
          );
      } catch (e) {
        if (context.mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('clubs').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        var clubs = snapshot.data!.docs;
        if (clubs.isEmpty)
          return const Center(child: Text("Kayıtlı kulüp yok."));

        return Padding(
          padding: const EdgeInsets.all(20),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              childAspectRatio: 3 / 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: clubs.length,
            itemBuilder: (context, index) {
              var doc = clubs[index];
              var data = doc.data() as Map<String, dynamic>;
              var theme = data['theme'] ?? {};
              Color primaryColor = hexToColor(
                theme['primaryColor'] ?? "0xFF00BCD4",
              );

              return Card(
                elevation: 4,
                child: Stack(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: primaryColor.withOpacity(0.2),
                          radius: 30,
                          child: Text(
                            data['shortName'] ?? "?",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          data['clubName'] ?? "İsimsiz",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          data['university'] ?? "ESOGU",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ), // ÜNİVERSİTE GÖSTERİMİ
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminPanel(
                                  kulupId: doc.id,
                                  kulupismi: data['clubName'],
                                  primaryColor: primaryColor,
                                  currentUserRole: 'baskan',
                                  isSuperAdmin: true,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.settings, size: 18),
                          label: const Text("Yönet"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _deleteClub(context, doc.id),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
