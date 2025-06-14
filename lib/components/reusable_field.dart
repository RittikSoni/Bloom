// lib/widgets/fancy_text_form_field.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loom_rs/constants/ktheme.dart';

enum ReusableFieldVariant { glass, outline, underline }

/// A reusable, “glassy” text form field with built‑in common validations.
///
/// Supports multiple visual styles, input types, and validation rules.
/// - `glass`: frosted glass effect with blur
/// - `outline`: standard outlined field
/// - `underline`: simple underline style
class ReusableTextFormField extends StatelessWidget {
  const ReusableTextFormField({
    super.key,
    this.controller,
    this.focusNode,
    this.variant = ReusableFieldVariant.glass,
    this.labelText,
    this.hintText,
    this.prefix,
    this.suffix,
    this.keyboardType,
    this.isMultiline = false,
    this.isEmail = false,
    this.isURL = false,
    this.isNumeric = false,
    this.minLength,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.borderRadius = 16.0,
    this.blurSigma = 10.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// The visual style of the field.
  ///
  /// Defaults to `ReusableFieldVariant.glass`.
  final ReusableFieldVariant variant;
  final String? labelText;
  final String? hintText;
  final Widget? prefix;
  final Widget? suffix;

  /// If true, allows multiple lines.
  ///
  /// Defaults to `false`.
  final bool isMultiline;

  /// Common validation flags
  final bool isEmail;
  final bool isURL;
  final bool isNumeric;
  final int? minLength;
  final int? maxLength;

  /// Custom validator (runs last, if provided)
  final String? Function(String?)? validator;

  final void Function(String)? onChanged;
  final bool enabled;

  /// Border radius for the field.
  ///
  /// Defaults to `16.0`.
  final double borderRadius;

  /// Blur effect strength for the glass variant.
  ///
  /// Defaults to `10.0`.
  /// Higher values create a stronger blur effect.
  /// Lower values create a subtler effect.
  final double blurSigma;

  /// Padding around the text field content.
  ///
  /// Defaults to `EdgeInsets.symmetric(horizontal: 16, vertical: 12)`.
  final EdgeInsetsGeometry padding;

  final TextInputType? keyboardType;

  String? _composedValidator(String? value) {
    final v = value ?? '';
    if (isNumeric && v.isNotEmpty && !RegExp(r'^\d+$').hasMatch(v)) {
      return 'Only numbers allowed';
    }
    if (isEmail &&
        v.isNotEmpty &&
        !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
      return 'Invalid email';
    }
    if (isURL &&
        v.isNotEmpty &&
        !RegExp(
          r'^(https?:\/\/)?' // protocol
          r'([a-zA-Z0-9_-]+\.)+[a-zA-Z]{2,6}' // domain
          r'(\/\S*)?$',
        ) // path
        .hasMatch(v)) {
      return 'Invalid URL';
    }
    if (minLength != null && v.length < minLength!) {
      return 'Min $minLength characters';
    }
    if (maxLength != null && v.length > maxLength!) {
      return 'Max $maxLength characters';
    }
    if (validator != null) {
      return validator!(value);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final enabledColor = Ktheme.primaryColor;
    final errorColor = theme.colorScheme.error;

    /// keyboard/input formatters
    TextInputType type = keyboardType ?? TextInputType.text;
    List<TextInputFormatter>? formatters;
    if (isNumeric) {
      type = TextInputType.number;
      formatters = [FilteringTextInputFormatter.digitsOnly];
    } else if (isMultiline) {
      type = TextInputType.multiline;
    } else if (isEmail) {
      type = TextInputType.emailAddress;
    } else if (isURL) {
      type = TextInputType.url;
    }

    // ---------- Build the border and decoration ----------
    InputBorder border;
    BoxDecoration? glassDecoration;
    switch (variant) {
      case ReusableFieldVariant.glass:
        glassDecoration = BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: LinearGradient(
            colors: [Colors.transparent, Colors.white.withValues(alpha: 0.25)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        );
        border = OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: Colors.transparent),
        );
        break;
      case ReusableFieldVariant.outline:
        glassDecoration = null;
        border = OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: enabledColor.withValues(alpha: 0.7)),
        );
        break;
      case ReusableFieldVariant.underline:
      default:
        glassDecoration = null;
        border = UnderlineInputBorder(
          borderSide: BorderSide(color: enabledColor.withValues(alpha: 0.7)),
        );
        break;
    }

    // --------- Build the TextFormField itself ----------
    final textField = TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: type,
      inputFormatters: formatters,
      obscureText: !isMultiline && false,
      minLines: isMultiline ? 3 : 1,
      maxLines: isMultiline ? null : 1,
      enabled: enabled,
      style: theme.textTheme.bodyMedium,
      validator: _composedValidator,
      onChanged: onChanged,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: padding,
        labelText: labelText,
        labelStyle: TextStyle(color: baseColor),
        hintText: hintText,
        hintStyle: TextStyle(color: baseColor.withValues(alpha: 0.5)),
        prefixIcon:
            prefix != null
                ? Padding(
                  padding: const EdgeInsets.only(left: 8, right: 4),
                  child: prefix,
                )
                : null,
        suffixIcon:
            suffix != null
                ? Padding(
                  padding: const EdgeInsets.only(right: 8, left: 4),
                  child: suffix,
                )
                : null,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: enabledColor, width: 2),
        ),
        errorBorder: border.copyWith(borderSide: BorderSide(color: errorColor)),
        focusedErrorBorder: border.copyWith(
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
      ),
    );

    if (variant == ReusableFieldVariant.glass) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              decoration: glassDecoration,
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: textField,
            ),
          ),
        ),
      );
    }

    return textField;
  }
}
