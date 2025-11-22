import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:unihub/utils/hex_color.dart';

class AdminSettingsTab extends StatefulWidget {
  final String kulupId;
  final Color primaryColor;

  const AdminSettingsTab({
    super.key,
    required this.kulupId,
    required this.primaryColor,
  });

  @override
  State<AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends State<AdminSettingsTab> {
  final _clubNameController = TextEditingController();
  final _shortNameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _clubDescController = TextEditingController();

  Color _pickerColor = Colors.cyan;
  Color _currentColor = Colors.cyan;
  String _selectedIconKey = 'groups';

  // İkon Listesi
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
    _loadClubSettings();
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
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ayarlar güncellendi!"),
            backgroundColor: Colors.green,
          ),
        );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
      );
    }
  }

  String _colorToHex(Color color) {
    return '0xFF${color.value.toRadixString(16).padLeft(8, '0').toUpperCase().substring(2)}';
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

  @override
  Widget build(BuildContext context) {
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
