import 'package:flutter/material.dart';

class CustomSquareButton extends StatelessWidget {
  final VoidCallback onTap;
  final String text;
  final Color color;
  final double size;
  final String assetPath;

  const CustomSquareButton({
    super.key,
    required this.onTap,
    required this.text,
    //this.color = const Color(0xFFDCEDC8),
    this.color = const Color(0xFFC8E6C9),
    this.size = 100.0,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click, // Change to desired cursor type
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                    assetPath,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 10),
              Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
