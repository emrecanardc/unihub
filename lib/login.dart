import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unihub/register.dart';
import 'package:unihub/main_hub.dart';

class girisEkrani extends StatefulWidget {
  const girisEkrani({super.key});

  @override
  State<girisEkrani> createState() => _girisEkraniState();
}

class _girisEkraniState extends State<girisEkrani> {
  final TextEditingController _numarakontrol = TextEditingController();
  final TextEditingController _sifrekontrol = TextEditingController();

  // Üniversite Domain Listesi
  final Map<String, String> _universities = {
    "ESOGU": "@ogrenci.ogu.edu.tr",
    "Anadolu": "@anadolu.edu.tr",
    "ESTÜ": "@ogrenci.estu.edu.tr",
  };

  String _selectedUniKey = "ESOGU"; // Varsayılan seçim
  bool _isLoading = false;
  bool _isObscured = true;

  @override
  void dispose() {
    _numarakontrol.dispose();
    _sifrekontrol.dispose();
    super.dispose();
  }

  Future<void> _girisYap() async {
    if (_numarakontrol.text.isEmpty || _sifrekontrol.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen okul no ve şifrenizi girin")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Seçilen üniversitenin domainini alıp birleştiriyoruz
    final String domain = _universities[_selectedUniKey]!;
    final String tamEposta = '${_numarakontrol.text.trim()}$domain';

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: tamEposta,
        password: _sifrekontrol.text.trim(),
      );

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainHub()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String hataMesaji = "Giriş başarısız.";
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        hataMesaji = "Okul numarası veya şifre hatalı.";
      } else if (e.code == 'wrong-password') {
        hataMesaji = "Şifre yanlış.";
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(hataMesaji), backgroundColor: Colors.red),
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 80, color: Colors.cyan),
              const SizedBox(height: 16),
              const Text(
                "Tekrar Hoş Geldin!",
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.cyan,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Giriş yapmak için bilgilerini gir",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 40),

              // --- BİRLEŞTİRİLMİŞ GİRİŞ ALANI ---
              // Öğrenci Numarası TextField'ının içine Dropdown'ı gömdük
              TextField(
                controller: _numarakontrol,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: "Öğrenci No",
                  prefixIcon: const Icon(
                    Icons.badge_outlined,
                    color: Colors.grey,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 12,
                  ),

                  // SAĞ TARAFA GÖMÜLÜ DROPDOWN
                  suffixIcon: Container(
                    margin: const EdgeInsets.only(right: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withOpacity(
                        0.1,
                      ), // Hafif mavi arka plan
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedUniKey,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.cyan,
                        ),
                        style: const TextStyle(
                          color: Colors.cyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        // Açılır menü arka planı
                        dropdownColor: Colors.white,
                        items: _universities.keys.map((String key) {
                          return DropdownMenuItem<String>(
                            value: key,
                            child: Text(
                              key,
                            ), // Sadece okul adı (ESOGU vb.) görünür
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedUniKey = newValue!;
                          });
                        },
                      ),
                    ),
                  ),
                  // Kenarlık ayarları
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(
                      color: Colors.cyan,
                      width: 2.0,
                    ),
                  ),
                ),
              ),

              // Bilgilendirme Metni (Hangi mail uzantısının seçildiğini gösterir)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Seçili uzantı: ${_universities[_selectedUniKey]}",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- ŞİFRE ---
              TextField(
                controller: _sifrekontrol,
                obscureText: _isObscured,
                decoration: InputDecoration(
                  hintText: "••••••••••",
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Colors.grey,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _isObscured = !_isObscured),
                    icon: Icon(
                      _isObscured ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(
                      color: Colors.cyan,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              _isLoading
                  ? const CircularProgressIndicator(color: Colors.cyan)
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(
                          double.infinity,
                          55,
                        ), // Biraz daha yüksek buton
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _girisYap,
                      child: const Text(
                        "Giriş Yap",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Hesabın yok mu?",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const kayitEkrani(),
                        ),
                      );
                    },
                    child: const Text(
                      "Kayıt Ol",
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
}
