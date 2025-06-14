import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class GlassmorphismTemplateWidget extends StatelessWidget {
  final String title;
  final String lottieAsset;

  const GlassmorphismTemplateWidget({
    super.key,
    required this.title,
    required this.lottieAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: Lottie.asset(lottieAsset, fit: BoxFit.cover)),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white30),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black26)],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
