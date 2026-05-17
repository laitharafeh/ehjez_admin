import 'package:flutter/material.dart';

/// A grey rectangle with a sweeping shimmer highlight.
/// Drop-in replacement for any loading placeholder — pass the same
/// dimensions as the real widget it replaces.
class ShimmerBox extends StatefulWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = 4,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment(-1.5 + _ctrl.value * 3, 0),
            end: Alignment(-0.8 + _ctrl.value * 3, 0),
            colors: const [
              Color(0xFFE0E0E0),
              Color(0xFFF0F0F0),
              Color(0xFFE0E0E0),
            ],
          ),
        ),
      ),
    );
  }
}
