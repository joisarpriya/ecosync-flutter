import 'package:flutter/material.dart';

class Skeleton extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadius borderRadius;

  const Skeleton.rect({super.key, this.height = 12, this.width = double.infinity, this.borderRadius = const BorderRadius.all(Radius.circular(8))});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade200, Colors.grey.shade300], begin: Alignment(-1, -0.3), end: Alignment(1, 0.3)),
      ),
    );
  }
}
