import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unihub/login.dart';

class UserProfileTab extends StatefulWidget {
  const UserProfileTab({super.key});

  @override
  State<UserProfileTab> createState() => _UserProfileTabState();
}

class _UserProfileTabState extends State<UserProfileTab> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _newPasswordController;

  bool _isObscured = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? "");
    _emailController = TextEditingController(text: user?.email ?? "");
    _newPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _showReAuthDialog() async {
    final passwordController = TextEditingController();
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.security, color: Colors.cyan),
              SizedBox(width: 10),
              Text("Güvenlik Doğrulaması"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Değişiklikleri kaydetmek için lütfen MEVCUT şifrenizi girin.",
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Mevcut Şifre",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                _saveChanges(passwordController.text.trim());
              },
              child: const Text("Onayla"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveChanges(String currentPassword) async {
    if (currentPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("İşlem için mevcut şifrenizi girmelisiniz."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      if (_nameController.text.trim() != user.displayName) {
        await user.updateDisplayName(_nameController.text.trim());
      }
      if (_newPasswordController.text.isNotEmpty) {
        if (_newPasswordController.text.length < 6)
          throw FirebaseAuthException(
            code: 'weak-password',
            message: "Yeni şifre en az 6 karakter olmalı.",
          );
        await user.updatePassword(_newPasswordController.text.trim());
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profil başarıyla güncellendi! ✅"),
            backgroundColor: Colors.green,
          ),
        );
        _newPasswordController.clear();
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Bir hata oluştu.";
      if (e.code == 'wrong-password')
        msg = "Mevcut şifreyi yanlış girdiniz.";
      else if (e.code == 'weak-password')
        msg = "Yeni şifre çok zayıf.";
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cikisYap(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const girisEkrani()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          "Profilim",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.cyan,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => _cikisYap(context),
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: "Çıkış Yap",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.cyan.shade100,
                    child: Text(
                      user?.displayName?.substring(0, 1).toUpperCase() ?? "U",
                      style: const TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyan,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.cyan,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            _buildLabel("Ad Soyad"),
            _buildTextField(
              controller: _nameController,
              icon: Icons.person,
              hint: "Adınız Soyadınız",
            ),
            const SizedBox(height: 20),
            _buildLabel("E-posta"),
            _buildTextField(
              controller: _emailController,
              icon: Icons.email,
              isReadOnly: true,
            ),
            const SizedBox(height: 20),
            _buildLabel("Şifre"),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5),
                ],
              ),
              child: TextField(
                controller: _newPasswordController,
                obscureText: _isObscured,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Colors.cyan,
                  ),
                  hintText: "Yeni Şifre (Değiştirmek istemiyorsan boş bırak)",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscured ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(() => _isObscured = !_isObscured),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _showReAuthDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Değişiklikleri Kaydet",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    bool isReadOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isReadOnly ? Colors.grey.shade200 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isReadOnly
            ? []
            : [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
      ),
      child: TextField(
        controller: controller,
        readOnly: isReadOnly,
        enabled: !isReadOnly,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: isReadOnly ? Colors.grey : Colors.cyan),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black87),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    );
  }
}
