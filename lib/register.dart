import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Kayıt için gerekli tüm alanların Controller'ları
  final _fullNameController = TextEditingController();
  final _schoolNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final String _studentDomain = "@ogrenci.ogu.edu.tr";

  // Controller'ları temizlemek için dispose metodu
  @override
  void dispose() {
    _fullNameController.dispose();
    _schoolNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Test için MaterialApp ekli, ana projeye entegre ederken bu kaldırılmalı
    // ve sayfa Navigator ile çağrılmalı.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 80),
                // İkon ve başlıklar
                const Icon(Icons.person_add_alt_1, size: 70, color: Colors.cyan),
                const SizedBox(height: 16),
                const Text(
                  "Hesap Oluştur",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    color: Colors.cyan,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Bilgilerini girerek aramıza katıl",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 30),

                // Form Alanları
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AD SOYAD ALANI
                    const Text(
                      "Ad Soyad",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        hintText: "Adın ve soyadın",
                        prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Colors.cyan, width: 2.0)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // OKUL NUMARASI ALANI
                    const Text(
                      "Okul Numarası",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _schoolNumberController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Okul numaranı gir",
                        prefixIcon: const Icon(Icons.school_outlined, color: Colors.grey),
                        suffixText: _studentDomain,
                        suffixStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Colors.cyan, width: 2.0)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ŞİFRE ALANI
                    const Text(
                      "Şifre",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "••••••••••",
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Colors.cyan, width: 2.0)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // ŞİFRE TEKRARI ALANI
                    const Text(
                      "Şifreyi Onayla",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "••••••••••",
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Colors.cyan, width: 2.0)),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // KAYIT OL BUTONU
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      ),
                      onPressed: () {
                        // TODO: Kayıt olma mantığı buraya gelecek
                        final fullName = _fullNameController.text;
                        final schoolNumber = _schoolNumberController.text;
                        final fullEmail = '$schoolNumber$_studentDomain';
                        final password = _passwordController.text;
                        print('Kayıt bilgileri: $fullName, $fullEmail, $password');
                      },
                      child: const Text(
                        "Kayıt Ol",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // GİRİŞ YAP LİNKİ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Zaten bir hesabın var mı?", style: TextStyle(color: Colors.grey[700])),
                        TextButton(
                          onPressed: () {
                            // TODO: Giriş yapma sayfasına geri dönme kodu buraya gelecek.
                            // Navigator.pop(context);
                            print("Giriş Yap tıklandı");
                          },
                          style: TextButton.styleFrom(foregroundColor: Colors.cyan),
                          child: const Text("Giriş Yap", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}