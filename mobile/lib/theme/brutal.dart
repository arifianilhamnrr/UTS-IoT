import 'package:flutter/material.dart';

/// Token desain Neobrutalism:
/// border hitam tebal, hard shadow tanpa blur, warna blok jenuh, sudut tegas.
class Brutal {
  static const ink = Color(0xFF111111);
  static const bg = Color(0xFFFFFDF5);
  static const paper = Color(0xFFFFFFFF);
  static const yellow = Color(0xFFFFD93D);
  static const pink = Color(0xFFFF6B9D);
  static const blue = Color(0xFF4D96FF);
  static const green = Color(0xFF6BCB77);
  static const red = Color(0xFFFF5252);
  static const orange = Color(0xFFFF9F1C);

  static const double border = 3;
  static const double radius = 6;

  static List<BoxShadow> shadow([double offset = 6]) => [
        BoxShadow(color: ink, offset: Offset(offset, offset), blurRadius: 0),
      ];
}

class BrutalCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final double shadowOffset;

  const BrutalCard({
    super.key,
    required this.child,
    this.color = Brutal.paper,
    this.padding = const EdgeInsets.all(18),
    this.shadowOffset = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Brutal.ink, width: Brutal.border),
        borderRadius: BorderRadius.circular(Brutal.radius),
        boxShadow: Brutal.shadow(shadowOffset),
      ),
      child: child,
    );
  }
}

/// Tombol dengan efek tekan mekanis: bergeser ke arah bayangan, bayangan hilang.
class BrutalPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String semanticLabel;

  const BrutalPressable({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel = 'Tombol',
  });

  @override
  State<BrutalPressable> createState() => _BrutalPressableState();
}

class _BrutalPressableState extends State<BrutalPressable> {
  bool _pressed = false;

  void _set(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          transform: Matrix4.translationValues(
            _pressed ? 4 : 0,
            _pressed ? 4 : 0,
            0,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Latar titik-titik khas neobrutalism.
class DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x14000000);
    const gap = 18.0;
    for (double x = 0; x < size.width; x += gap) {
      for (double y = 0; y < size.height; y += gap) {
        canvas.drawCircle(Offset(x, y), 1.4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
