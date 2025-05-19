import 'dart:async';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';

class ConfettiScreen extends StatefulWidget {
  const ConfettiScreen({super.key});

  @override
  State<ConfettiScreen> createState() => _ConfettiScreenState();
}

class _ConfettiScreenState extends State<ConfettiScreen> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    // 2‑second blast
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    )..play();

    // Schedule window close shortly after the blast
    Future.delayed(const Duration(milliseconds: 2500), () async {
      final subWindowIds = await DesktopMultiWindow.getAllSubWindowIds();
      for (final windowId in subWindowIds) {
        WindowController.fromWindowId(windowId).close();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // keep window fully see‑through
      body: Stack(
        children: [
          // bottom-left burst
          Align(
            alignment: Alignment.bottomLeft,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -pi / 4, // up‑right
              emissionFrequency: 0.05,
              numberOfParticles: 100,
              maxBlastForce: 100,
              minBlastForce: 5,
              gravity: 0.3,
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),

          // bottom-right burst
          Align(
            alignment: Alignment.bottomRight,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -3 * pi / 4, // up‑left
              emissionFrequency: 0.05,
              numberOfParticles: 100,
              maxBlastForce: 100,
              minBlastForce: 5,
              gravity: 0.3,
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
