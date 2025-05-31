import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Window.initialize();
  await windowManager.ensureInitialized();
  windowManager.setSize(Size(320, 320), animate: true);
  windowManager.setAsFrameless();
  windowManager.setAlignment(Alignment.topRight, animate: true);

  await Window.hideWindowControls();
  await Window.hideTitle();

  Window.makeWindowFullyTransparent();
  await Window.setEffect(effect: WindowEffect.transparent);

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: OptionsWheel(
            icons: [
              Icons.ac_unit,
              Icons.sports_martial_arts,
              Icons.fingerprint_rounded,
              Icons.shield,
              Icons.healing,
              Icons.radio_button_checked,
              Icons.ac_unit,
              Icons.sports_martial_arts,
              Icons.local_fire_department,
              Icons.shield,
              Icons.healing,
              Icons.radio_button_checked,
            ],
            onSelected: (index) {
              print("Selected index: $index");
            },
          ),
        ),
      ),
    ),
  );
}

class OptionsWheel extends StatefulWidget {
  final List<IconData> icons;
  final void Function(int index) onSelected;

  const OptionsWheel({
    super.key,
    required this.icons,
    required this.onSelected,
  });

  @override
  OptionsWheelState createState() => OptionsWheelState();
}

class OptionsWheelState extends State<OptionsWheel> {
  int? highlighted;
  Offset center = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final size = constraints.biggest;
        center = size.center(Offset.zero);
        final radius = 120.0;

        final startAngle = -pi / 2;
        final sliceAngle = 2 * pi / widget.icons.length;

        return GestureDetector(
          onPanStart: (details) {
            _updateHighlight(
              details.localPosition,
              radius,
              startAngle,
              sliceAngle,
            );
          },
          onPanUpdate: (details) {
            _updateHighlight(
              details.localPosition,
              radius,
              startAngle,
              sliceAngle,
            );
          },
          onPanEnd: (_) {
            if (highlighted != null) widget.onSelected(highlighted!);
            setState(() => highlighted = null);
          },
          child: Stack(
            children: [
              // Draw the wheel slices at exactly `radius`
              Positioned.fill(
                child: CustomPaint(
                  painter: _WheelPainter(
                    count: widget.icons.length,
                    center: center,
                    highlighted: highlighted,
                    radius: radius,
                    startAngle: startAngle,
                  ),
                ),
              ),

              // Glass blur overlay
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(color: Colors.transparent),
                ),
              ),

              ...List.generate(widget.icons.length, (i) {
                final angle = startAngle + sliceAngle * i;
                final iconOffset = Offset(
                  center.dx + cos(angle) * radius,
                  center.dy + sin(angle) * radius,
                );
                final isHighlighted = i == highlighted;

                return Positioned(
                  left: iconOffset.dx - 28,
                  top: iconOffset.dy - 28,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 150),
                    padding: EdgeInsets.all(isHighlighted ? 12 : 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(
                        isHighlighted ? 0.2 : 0.1,
                      ),
                      border:
                          isHighlighted
                              ? Border.all(color: Colors.cyanAccent, width: 3)
                              : null,
                      boxShadow:
                          isHighlighted
                              ? [
                                BoxShadow(
                                  color: Colors.cyanAccent.withOpacity(0.6),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                ),
                              ]
                              : [],
                    ),
                    child: Transform.scale(
                      scale: isHighlighted ? 1.2 : 1.0,
                      child: Icon(
                        widget.icons[i],
                        size: isHighlighted ? 36 : 28,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _updateHighlight(
    Offset localPos,
    double radius,
    double startAngle,
    double sliceAngle,
  ) {
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    var angle = atan2(dy, dx);
    // normalize so 0 is at +x, but we want 0 at startAngle:
    // shift by +pi/2 so 0 becomes top, then wrap
    angle = (angle - startAngle + 2 * pi) % (2 * pi);
    final idx = (angle / sliceAngle).floor();
    setState(() => highlighted = idx);
  }
}

class _WheelPainter extends CustomPainter {
  final int count;
  final Offset center;
  final int? highlighted;
  final double radius;
  final double startAngle;

  _WheelPainter({
    required this.count,
    required this.center,
    required this.highlighted,
    required this.radius,
    required this.startAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sliceAngle = 2 * pi / count;
    final paint =
        Paint()
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10);

    for (int i = 0; i < count; i++) {
      paint.color =
          i == highlighted
              ? Colors.cyanAccent.withOpacity(0.25)
              : Colors.transparent;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + sliceAngle * i - sliceAngle / 2,
        sliceAngle,
        true,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) =>
      old.highlighted != highlighted;
}
