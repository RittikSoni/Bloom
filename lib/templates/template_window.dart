// template_window.dart
import 'package:flutter/material.dart';
import 'package:loom_rs/templates/template_gradient.dart';

class TemplateWindow extends StatelessWidget {
  const TemplateWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.transparent,

        body: Stack(
          children: const [
            // Pick one of the widgets here, or use a selector
            GradientNeonTemplateWidget(title: 'Yo!', subtitle: '...'),
            // MinimalTemplateWidget(title: 'Recording...', subtitle: 'This is a demo', avatarUrl: null),
            // GlassmorphismTemplateWidget(title: 'Recording Live', lottieAsset: 'assets/particles.json'),
          ],
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
