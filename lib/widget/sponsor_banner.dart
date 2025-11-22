import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SponsorBanner extends StatelessWidget {
  const SponsorBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Sadece gerçek veritabanını dinle
      stream: FirebaseFirestore.instance
          .collection('app_sponsors')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        // 1. Yükleniyor veya Hata Durumu
        if (snapshot.hasError) return const SizedBox(); // Hata varsa gizle
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator(color: Colors.cyan)),
          );
        }

        // 2. Veri Yoksa Gizle
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        var sponsors = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Row(
                children: [
                  Icon(Icons.stars, color: Colors.amber, size: 24),
                  SizedBox(width: 8),
                  Text(
                    "Fırsatlar & Sponsorlar",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // YATAY KAYDIRILABİLİR BANNER ALANI
            SizedBox(
              height: 160, // Banner yüksekliği
              child: PageView.builder(
                controller: PageController(
                  viewportFraction: 0.9,
                ), // Yan kartların ucu görünsün
                itemCount: sponsors.length,
                itemBuilder: (context, index) {
                  var data = sponsors[index].data() as Map<String, dynamic>;
                  return _buildPremiumCard(data);
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildPremiumCard(Map<String, dynamic> data) {
    String? imageUrl = data['imageUrl'];
    String name = data['name'] ?? "Sponsor";
    String description = data['description'] ?? "";

    // Web panelinden renk seçimi eklemediğimiz için varsayılan renkler atayalım
    // İstersen web panele renk seçici de ekleyebiliriz ama şimdilik sabit
    int colorVal = 0xFF00BCD4;
    IconData icon = Icons.store;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 1. ARKA PLAN RESMİ
            Positioned.fill(
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: Color(colorVal).withOpacity(0.2),
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Container(color: Color(colorVal).withOpacity(0.2)),
            ),

            // 2. KARARTMA GRADYANI
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
            ),

            // 3. SOL ÜST "SPONSOR" ETİKETİ
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                  boxShadow: [
                    const BoxShadow(color: Colors.black12, blurRadius: 4),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified, color: Colors.amber, size: 14),
                    SizedBox(width: 4),
                    Text(
                      "SPONSOR",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. İÇERİK METİNLERİ
            Positioned(
              bottom: 15,
              left: 15,
              right: 15,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Color(colorVal), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (description.isNotEmpty)
                          Text(
                            description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white70,
                    size: 16,
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
