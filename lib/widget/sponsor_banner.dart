import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SponsorBanner extends StatefulWidget {
  const SponsorBanner({super.key});

  @override
  State<SponsorBanner> createState() => _SponsorBannerState();
}

class _SponsorBannerState extends State<SponsorBanner> {
  // DEMO VERİLERİ (Veritabanı boşken bunlar görünür)
  final List<Map<String, dynamic>> _demoSponsors = [
    {
      "name": "Kampüs Kırtasiye",
      "description": "ÜniHub üyelerine tüm notlarda %20 indirim!",
      "color": 0xFFE65100, // Turuncu
      "icon": Icons.edit_note,
      "imageUrl":
          "https://images.unsplash.com/photo-1503699645885-5050b7353f69?auto=format&fit=crop&w=800&q=80", // Örnek resim
    },
    {
      "name": "Mola Cafe",
      "description": "Vize haftası kahveler bizden. 1 Alana 1 Bedava!",
      "color": 0xFF5D4037, // Kahve Rengi
      "icon": Icons.coffee,
      "imageUrl":
          "https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=800&q=80", // Örnek resim
    },
    {
      "name": "TeknoStore",
      "description": "Kulüp etkinlikleri için teknolojik destek.",
      "color": 0xFF1565C0, // Mavi
      "icon": Icons.headphones,
      "imageUrl":
          "https://images.unsplash.com/photo-1550009158-9ebf69173e03?auto=format&fit=crop&w=800&q=80",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('app_sponsors').snapshots(),
      builder: (context, snapshot) {
        // Gerçek veri varsa onu kullan, yoksa DEMO verilerini kullan
        List<dynamic> sponsors = [];
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          sponsors = snapshot.data!.docs;
        } else {
          sponsors = _demoSponsors;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Row(
                children: [
                  Text(
                    "Fırsatlar & Sponsorlar",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.stars, color: Colors.amber, size: 24),
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
                  // Veri tipine göre (Firestore Doc veya Demo Map) veriyi al
                  var data = sponsors[index] is DocumentSnapshot
                      ? (sponsors[index] as DocumentSnapshot).data()
                            as Map<String, dynamic>
                      : sponsors[index] as Map<String, dynamic>;

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
    int colorVal = data['color'] ?? 0xFF00BCD4;
    IconData icon = data['icon'] ?? Icons.store;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5), // Kartlar arası boşluk
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
              child: imageUrl != null && imageUrl.startsWith('http')
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) =>
                          Container(color: Color(colorVal).withOpacity(0.2)),
                    )
                  : Container(color: Color(colorVal).withOpacity(0.2)),
            ),

            // 2. KARARTMA GRADYANI (Yazıların okunması için)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.85), // Alt kısım siyahlaşıyor
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
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    const Text(
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
                  // Logo/İkon Kutusu
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Color(colorVal), size: 24),
                  ),
                  const SizedBox(width: 12),
                  // Yazılar
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
                  // Ok İkonu
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
