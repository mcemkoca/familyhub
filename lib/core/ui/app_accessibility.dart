import 'package:flutter/material.dart';

/// Accessibility wrapper widgets to ensure consistent semantic labeling,
/// focus management, and screen reader support across the app.
///
/// Usage: Wrap any interactive widget with [AppSemanticButton], [AppSemanticIcon],
/// or [AppSemanticImage] to provide screen-reader descriptions.

/// Wraps a widget with a [Semantics] node and optional [FocusNode].
class AppSemanticWrapper extends StatelessWidget {
  const AppSemanticWrapper({
    super.key,
    required this.child,
    this.label,
    this.hint,
    this.button = false,
    this.focusNode,
  });

  final Widget child;
  final String? label;
  final String? hint;
  final bool button;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    Widget result = Semantics(
      label: label,
      hint: hint,
      button: button,
      child: child,
    );

    if (focusNode != null) {
      result = Focus(
        focusNode: focusNode,
        child: result,
      );
    }

    return result;
  }
}

/// An [IconButton] with mandatory [semanticLabel] and [FocusNode].
class AppSemanticIconButton extends StatelessWidget {
  const AppSemanticIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.focusNode,
    this.tooltip,
    this.color,
  });

  final Widget icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final String? tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: IconButton(
        icon: icon,
        onPressed: onPressed,
        focusNode: focusNode,
        tooltip: tooltip ?? semanticLabel,
        color: color,
      ),
    );
  }
}

/// A tappable card with [Semantics] and [FocusNode] support.
class AppSemanticCard extends StatelessWidget {
  const AppSemanticCard({
    super.key,
    required this.child,
    required this.semanticLabel,
    this.onTap,
    this.focusNode,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 12,
  });

  final Widget child;
  final String semanticLabel;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final EdgeInsets padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(padding: padding, child: child),
    );

    Widget result = Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              child: card,
            )
          : card,
    );

    if (focusNode != null) {
      result = Focus(focusNode: focusNode, child: result);
    }

    return result;
  }
}

/// An image with mandatory [semanticLabel] for screen readers.
class AppSemanticImage extends StatelessWidget {
  const AppSemanticImage({
    super.key,
    required this.imageProvider,
    required this.semanticLabel,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final ImageProvider imageProvider;
  final String semanticLabel;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: Image(
        image: imageProvider,
        width: width,
        height: height,
        fit: fit,
      ),
    );
  }
}

/// A text field with [TextInputAction], [FocusNode], and [semanticLabel].
class AppSemanticTextField extends StatelessWidget {
  const AppSemanticTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.semanticLabel,
    this.hintText,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.validator,
    this.onFieldSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? semanticLabel;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? hintText,
      textField: true,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        validator: validator,
        onFieldSubmitted: onFieldSubmitted,
        maxLines: maxLines,
        autofocus: autofocus,
      ),
    );
  }
}
