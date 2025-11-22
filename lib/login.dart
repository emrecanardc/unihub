import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unihub/register.dart';
import 'package:unihub/widget/widget_Test2.dart'; // Ana sayfan
import 'package:unihub/main_hub.dart';

class girisEkrani extends StatefulWidget {
  const girisEkrani({super.key});

  @override
  State<girisEkrani> createState() => _girisEkraniState();
}

class _girisEkraniState extends State<girisEkrani> {
  final TextEditingController _numarakontrol = TextEditingController();
  final TextEditingController _sifrekontrol = TextEditingController();
  final String _oguDomain = "@ogrenci.ogu.edu.tr";

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

    setState(() {
      _isLoading = true;
    });

    final String tamEposta = '${_numarakontrol.text.trim()}$_oguDomain';

    try {
      // 1. Giriş Yapmayı Dene
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: tamEposta,
            password: _sifrekontrol.text.trim(),
          );

      // 2. E-POSTA ONAY KONTROLÜ (Mail Verification Check)
      /* if (userCredential.user != null) {
        if (!userCredential.user!.emailVerified) {
          // Eğer onaylı değilse oturumu kapat
          await FirebaseAuth.instance.signOut();

          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("E-posta Onaylanmadı"),
                content: const Text(
                  "Giriş yapabilmek için lütfen e-postanıza gelen doğrulama linkine tıklayınız.\n(Spam/Gereksiz klasörünü kontrol etmeyi unutmayın)",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Tamam"),
                  ),
                ],
              ),
            );
          }
          return; // Fonksiyondan çık, ana sayfaya gitme
        }
      }
      */
      // 3. Her şey tamamsa Ana Sayfaya Git
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
      } else if (e.code == 'too-many-requests') {
        hataMesaji = "Çok fazla denediniz, lütfen biraz bekleyin.";
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 100),
            const Icon(Icons.book, size: 80, color: Colors.cyan),
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
              "Hesabına giriş yap",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Öğrenci Numarası",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _numarakontrol,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Okul Numaranız",
                      prefixIcon: const Icon(
                        Icons.school_outlined,
                        color: Colors.grey,
                      ),
                      suffixText: _oguDomain,
                      suffixStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                      ),
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
                  const SizedBox(height: 20),

                  const Text(
                    "Şifre",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
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
                        onPressed: () {
                          setState(() {
                            _isObscured = !_isObscured;
                          });
                        },
                        icon: Icon(
                          _isObscured ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                      ),
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
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.cyan),
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyan,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          onPressed: _girisYap,
                          child: const Text(
                            "Giriş Yap",
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
          ],
        ),
      ),
    );
  }
}
