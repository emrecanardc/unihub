import 'package:flutter/material.dart';

class kayitEkrani extends StatelessWidget {
  const kayitEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          // 1. DEĞİŞİKLİK: Bu Column'un çocuklarını yatayda ortala.
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 100),
            const Icon(Icons.man_2_sharp, size: 150, color: Colors.cyan),
            const SizedBox(height: 10),
            const Text("Hesap Oluştur", style: TextStyle(fontSize: 35)),
            const SizedBox(height: 10), // Metinler arasına küçük bir boşluk ekledim.
            const Text("Bilgilerini girerek aramıza katıl"),
            const SizedBox(height: 20), // Form alanları için boşluk.
            
            // "data" yazısı için olan bölüm
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                // 2. DEĞİŞİKLİK: Bu iç Column'u yatayda genişlet.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  Text(
                    "data",
                    // 3. DEĞİŞİKLİK: Metni sola yasla.
                    textAlign: TextAlign.start, 
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}