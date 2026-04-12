import 'package:flutter/material.dart';

class CustomSquareButton extends StatelessWidget {
  final VoidCallback onTap;
  final String text;
  final IconData icon;
  final Color color;
  final double size;

  const CustomSquareButton({
    super.key,
    required this.onTap,
    required this.text,
    required this.icon,
    this.color = const Color(0xFFC8E6C9),
    this.size = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  size: size * 0.45,
                  color: const Color(0xFF068631),
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
