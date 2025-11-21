import 'package:flutter/material.dart';

class ClubAboutTab extends StatelessWidget {
  final String description;
  final String category;
  final Color primaryColor;
  final Color secondaryColor;

  const ClubAboutTab({
    super.key,
    required this.description,
    required this.category,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Kulüp Hakkında",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Chip(
            label: Text(category),
            backgroundColor: secondaryColor.withOpacity(0.5),
            avatar: Icon(Icons.category, size: 18, color: primaryColor),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
