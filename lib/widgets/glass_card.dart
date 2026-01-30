import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  final double blur;
  final List<BoxShadow>? shadows;
  final bool animate;

  const GlassCard({super.key, required this.child, this.borderRadius = 14.0, this.padding = const EdgeInsets.all(12), this.blur = 8.0, this.shadows, this.animate = false});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).cardColor.withOpacity(0.6);

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: shadows ?? [BoxShadow(blurRadius: 18, color: Colors.black.withOpacity(0.08), offset: const Offset(0, 6))],
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: child,
        ),
      ),
    );

    if (animate) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.96, end: 1.0),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutBack,
        builder: (context, scale, _) => Transform.scale(scale: scale, child: Opacity(opacity: ((scale - 0.96) / (1 - 0.96)).clamp(0.0, 1.0), child: content)),
      );
    }

    return content;
  }
}
