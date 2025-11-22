import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class kayitEkrani extends StatefulWidget {
  const kayitEkrani({super.key});

  @override
  State<kayitEkrani> createState() => _kayitEkraniState();
}

class _kayitEkraniState extends State<kayitEkrani> {
  final TextEditingController _adSoyadController = TextEditingController();
  final TextEditingController _okulNoController = TextEditingController();
  final TextEditingController _sifreController = TextEditingController();

  // Üniversite Listesi
  final Map<String, String> _universities = {
    "ESOGU": "@ogrenci.ogu.edu.tr",
    "Anadolu": "@anadolu.edu.tr",
    "ESTÜ": "@ogrenci.estu.edu.tr",
  };

  String _selectedUniKey = "ESOGU"; // Varsayılan
  bool _isLoading = false;

  @override
  void dispose() {
    _adSoyadController.dispose();
    _okulNoController.dispose();
    _sifreController.dispose();
    super.dispose();
  }

  Future<void> _kayitOl() async {
    if (_adSoyadController.text.isEmpty ||
        _okulNoController.text.isEmpty ||
        _sifreController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Seçilen üniversiteye göre mail oluştur
    final String domain = _universities[_selectedUniKey]!;
    final String tamEposta = '${_okulNoController.text.trim()}$domain';

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: tamEposta,
            password: _sifreController.text.trim(),
          );

      await userCredential.user?.updateDisplayName(
        _adSoyadController.text.trim(),
      );

      // E-posta doğrulama
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        await userCredential.user!.sendEmailVerification();
      }

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text("Doğrulama Maili Gönderildi"),
            content: Text(
              "$tamEposta adresine doğrulama linki gönderdik.\n\nLütfen mail kutunuzu kontrol edin.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text("Tamam"),
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String hata = "Hata oluştu";
      if (e.code == 'email-already-in-use')
        hata = "Bu numara zaten kayıtlı.";
      else if (e.code == 'weak-password')
        hata = "Şifre zayıf.";

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(hata), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (context.mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.cyan),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Icon(Icons.person_add_alt_1, size: 80, color: Colors.cyan),
              const SizedBox(height: 16),
              const Text(
                "Aramıza Katıl",
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.cyan,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 40),

              // AD SOYAD
              _buildTextField(
                controller: _adSoyadController,
                label: "Ad Soyad",
                hint: "Adınız Soyadınız",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),

              // ÜNİVERSİTE SEÇİMİ
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      "Üniversite",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedUniKey,
                        isExpanded: true,
                        items: _universities.keys.map((String key) {
                          return DropdownMenuItem<String>(
                            value: key,
                            child: Text(key),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedUniKey = val!),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // OKUL NO
              _buildTextField(
                controller: _okulNoController,
                label: "Öğrenci No / Kullanıcı Adı",
                hint: "Numaranız",
                icon: Icons.school_outlined,
              ),
              const SizedBox(height: 20),

              // ŞİFRE
              _buildTextField(
                controller: _sifreController,
                label: "Şifre",
                hint: "••••••••••",
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 30),

              // KAYIT BUTONU
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.cyan)
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _kayitOl,
                      child: const Text(
                        "Kayıt Ol",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
