// lib/widgets/glassy_radio_list_tile.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loom_rs/constants/ktheme.dart';

/// A glassy, big‑tech style radio list tile with
/// backdrop blur, gradient, border and ripple feedback.
///
/// This widget is designed to mimic the frosted glass effect
/// seen in modern UI designs, providing a visually appealing
/// and interactive radio button experience.
class GlassyRadioListTile<T> extends StatelessWidget {
  const GlassyRadioListTile({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.icon,
    this.label,
    this.subtitle,
    this.trailing,
    this.activeColor,
    this.enabled = true,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
    this.borderRadius = 16.0,
    this.blurSigma = 20.0,
    this.gradientColors = const [Colors.white54, Colors.white24],
    this.borderColor = Colors.white30,
    this.shadowColor = Colors.black26,
    this.splashColor,
  });

  /// The value represented by this tile.
  final T value;

  /// The currently selected value for the group.
  final T groupValue;

  /// Called when the user selects this tile.
  final ValueChanged<T?> onChanged;

  /// Optional leading icon.
  final IconData? icon;

  /// Primary text.
  final String? label;

  /// Secondary text below the label.
  final String? subtitle;

  /// Optional widget at the end.
  final Widget? trailing;

  /// Color of the selected radio and ripple.
  final Color? activeColor;

  /// If false, tile is disabled.
  final bool enabled;

  /// Padding around the tile content.
  final EdgeInsetsGeometry contentPadding;

  /// Corner radius of the glass panel.
  final double borderRadius;

  /// Strength of the backdrop blur.
  final double blurSigma;

  /// Gradient for the frosted fill.
  final List<Color> gradientColors;

  /// Border color of the glass panel.
  final Color borderColor;

  /// Shadow color under the panel.
  final Color shadowColor;

  /// Ripple color override.
  final Color? splashColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool selected = value == groupValue;
    final Color resolvedActive = activeColor ?? Ktheme.primaryColor;
    final Color resolvedSplash = splashColor ?? Ktheme.primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap:
                    enabled
                        ? () {
                          HapticFeedback.selectionClick();
                          onChanged(value);
                        }
                        : null,
                borderRadius: BorderRadius.circular(borderRadius),
                splashColor: resolvedSplash,
                child: Padding(
                  padding: contentPadding,
                  child: Row(
                    children: [
                      // radio
                      Radio<T>(
                        value: value,
                        groupValue: groupValue,
                        onChanged: enabled ? onChanged : null,
                        activeColor: resolvedActive,
                      ),

                      // optional icon
                      if (icon != null) ...[
                        Icon(
                          icon,
                          size: 20,
                          color:
                              enabled
                                  ? (selected
                                      ? resolvedActive
                                      : theme.iconTheme.color)
                                  : theme.disabledColor,
                        ),
                        const SizedBox(width: 8),
                      ],

                      // label & subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (label != null)
                              Text(
                                label!,
                                style: theme.textTheme.bodyLarge!.copyWith(
                                  color:
                                      enabled
                                          ? theme.textTheme.bodyLarge!.color
                                          : theme.disabledColor,
                                ),
                              ),
                            if (subtitle != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  subtitle!,
                                  style: theme.textTheme.bodyMedium!.copyWith(
                                    color:
                                        enabled
                                            ? theme.textTheme.bodyMedium!.color
                                            : theme.disabledColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // optional trailing
                      if (trailing != null) ...[
                        const SizedBox(width: 8),
                        trailing!,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
