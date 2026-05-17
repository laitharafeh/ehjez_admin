import 'package:flutter/material.dart';

class CustomSquareButton extends StatefulWidget {
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
  State<CustomSquareButton> createState() => _CustomSquareButtonState();
}

class _CustomSquareButtonState extends State<CustomSquareButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.06 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: _hovered
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Icon(
                    widget.icon,
                    size: widget.size * 0.45,
                    color: const Color(0xFF068631),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.text,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
