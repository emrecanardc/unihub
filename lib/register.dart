import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class kayitEkrani extends StatefulWidget {
  const kayitEkrani({super.key});

  @override
  State<kayitEkrani> createState() => _kayitEkraniState();
}

class _kayitEkraniState extends State<kayitEkrani> {
  // Form verilerini tutacak kontrolcüler
  final TextEditingController _adSoyadController = TextEditingController();
  final TextEditingController _okulNoController = TextEditingController();
  final TextEditingController _sifreController = TextEditingController();

  // Okul domaini sabit
  final String _oguDomain = "@ogrenci.ogu.edu.tr";

  // Yükleniyor animasyonu için değişken
  bool _isLoading = false;

  @override
  void dispose() {
    _adSoyadController.dispose();
    _okulNoController.dispose();
    _sifreController.dispose();
    super.dispose();
  }

  // Kayıt Ol Fonksiyonu
  Future<void> _kayitOl() async {
    // 1. Boş alan kontrolü
    if (_adSoyadController.text.isEmpty ||
        _okulNoController.text.isEmpty ||
        _sifreController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 2. E-posta oluşturma (Okul no + Domain)
    final String tamEposta = '${_okulNoController.text.trim()}$_oguDomain';

    try {
      // 3. Firebase'de kullanıcı oluşturma
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: tamEposta,
            password: _sifreController.text.trim(),
          );

      // 4. İsim bilgisini ekleme
      await userCredential.user?.updateDisplayName(
        _adSoyadController.text.trim(),
      );

      // 5. E-POSTA DOĞRULAMA LİNKİ GÖNDERME
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        await userCredential.user!.sendEmailVerification();
      }

      if (context.mounted) {
        // Başarılı Dialog Göster
        showDialog(
          context: context,
          barrierDismissible: false, // Boşluğa basınca kapanmasın
          builder: (context) => AlertDialog(
            title: const Text("Doğrulama Maili Gönderildi"),
            content: Text(
              "$tamEposta adresine doğrulama linki gönderdik.\n\nLütfen mail kutunuzu (Gereksiz/Spam klasörü dahil) kontrol edin ve linke tıkladıktan sonra giriş yapın.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Dialogu kapat
                  Navigator.pop(context); // Login ekranına dön
                },
                child: const Text("Tamam"),
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String hataMesaji = "Bir hata oluştu";
      if (e.code == 'email-already-in-use') {
        hataMesaji = "Bu okul numarası zaten kayıtlı.";
      } else if (e.code == 'weak-password') {
        hataMesaji = "Şifre çok zayıf (en az 6 karakter olmalı).";
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(hataMesaji), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (context.mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
            mainAxisAlignment: MainAxisAlignment.center,
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
              const SizedBox(height: 8),
              Text(
                "ÜniHub hesabını oluştur",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 40),

              // Ad Soyad
              _buildTextField(
                controller: _adSoyadController,
                label: "Ad Soyad",
                hint: "Adınız Soyadınız",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),

              // Okul No
              _buildTextField(
                controller: _okulNoController,
                label: "Öğrenci Numarası",
                hint: "Okul Numaranız",
                icon: Icons.school_outlined,
                isNumber: true,
                suffix: _oguDomain,
              ),
              const SizedBox(height: 20),

              // Şifre
              _buildTextField(
                controller: _sifreController,
                label: "Şifre",
                hint: "••••••••••",
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 30),

              // Buton
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.cyan)
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
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

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Zaten hesabın var mı?",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Giriş Yap",
                      style: TextStyle(
                        color: Colors.cyan,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
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
    bool isNumber = false,
    String? suffix,
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
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey),
            suffixText: suffix,
            suffixStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.cyan, width: 2.0),
            ),
          ),
        ),
      ],
    );
  }
}
