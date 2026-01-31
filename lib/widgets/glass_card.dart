import 'package:flutter/material.dart';

import '../theme/theme_config.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  final double blur;
  final List<BoxShadow>? shadows;
  final bool animate;

  const GlassCard({super.key, required this.child, this.borderRadius = ThemeConfig.cardRadius, this.padding = const EdgeInsets.all(16), this.blur = 6.0, this.shadows, this.animate = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      elevation: 0,
      child: Padding(padding: padding, child: child),
    );
  }
}
