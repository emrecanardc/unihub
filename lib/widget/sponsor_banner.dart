import 'package:flutter/material.dart';

class SponsorBanner extends StatelessWidget {
  const SponsorBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // DEMO SPONSOR VERİLERİ
    // Burayı istediğin gibi çoğaltabilir veya değiştirebilirsin.
    final List<Map<String, String>> demoSponsors = [
      {
        "name": "Kampüs Kırtasiye",
        "description": "Tüm notlarda %20 indirim!",
        "imageUrl":
            "https://images.unsplash.com/photo-1654931800100-2ecf6eee7c64?q=80&w=2070&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
      },
      {
        "name": "Mola Cafe",
        "description": "1 Kahve Alana 1 Bedava",
        "imageUrl":
            "https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=800&q=80",
      },
      {
        "name": "TeknoStore",
        "description": "Teknolojik aksesuarlarda öğrenci indirimi.",
        "imageUrl":
            "https://images.unsplash.com/photo-1550009158-9ebf69173e03?auto=format&fit=crop&w=800&q=80",
      },
    ];

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

        // YATAY KAYDIRILABİLİR ALAN
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: PageController(
              viewportFraction: 0.9,
            ), // Yan kartların ucu görünsün
            itemCount: demoSponsors.length,
            itemBuilder: (context, index) {
              var data = demoSponsors[index];
              return _buildSponsorCard(data);
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // KART TASARIMI
  Widget _buildSponsorCard(Map<String, String> data) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
        // Arka plan resmi
        image: DecorationImage(
          image: NetworkImage(data["imageUrl"]!),
          fit: BoxFit.cover,
          // Resmin üzerine hafif siyah filtre atalım ki yazılar okunsun
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.5),
            BlendMode.darken,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // SOL ÜST "SPONSOR" ETİKETİ
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "SPONSOR",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // ALTTAKİ YAZILAR
          Positioned(
            bottom: 15,
            left: 15,
            right: 15,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data["name"]!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                ),
                Text(
                  data["description"]!,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
