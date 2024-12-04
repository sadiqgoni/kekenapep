import 'package:flutter/material.dart';

class HeaderSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final double screenWidth;
  final double screenHeight;

  const HeaderSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: screenHeight * 0.2,
      decoration: const BoxDecoration(
        color: Color(0xFFFDB300),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.08,
          vertical: screenHeight * 0.03,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Text(
              title,
              style: TextStyle(
                color: Colors.black,
                fontSize: screenWidth * 0.068,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.black,
                fontSize: screenWidth * 0.038,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
