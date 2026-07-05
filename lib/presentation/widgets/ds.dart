/// FamilyHub Design System — shared dark-premium widgets
library;

import 'package:flutter/material.dart';
import '../../config/constants.dart';

// ─── Colors / tokens ─────────────────────────────────────────────────────────
abstract class Ds {
  static const bg = Color(0xFF0A0A0F);
  static const card = Color(0xFF13131A);
  static const glass = Color(0x1AFFFFFF);
  static const glassBorder = Color(0x1EFFFFFF);
  static const indigo = Color(0xFF6366F1);
  static const indigoLight = Color(0xFF818CF8);
  static const pink = Color(0xFFEC4899);
  static const text = Color(0xFFE5E7EB);
  static const textSub = Color(0xFF9CA3AF);
  static const textMuted = Color(0xFF4B5563);
  static const divider = Color(0xFF1F2937);
}

// ─── GlassCard ───────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = 18,
    this.color,
    this.borderColor,
    this.shadows,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Ds.glass,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? Ds.glassBorder,
          width: 0.5,
        ),
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap != null) {
      content = GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }
}

// ─── AccentCard (colored left border) ────────────────────────────────────────
class AccentCard extends StatelessWidget {
  final Widget child;
  final Color accent;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const AccentCard({
    super.key,
    required this.child,
    required this.accent,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: accent, width: 3),
          top: BorderSide(color: accent.withAlpha(40), width: 0.5),
          right: BorderSide(color: accent.withAlpha(40), width: 0.5),
          bottom: BorderSide(color: accent.withAlpha(40), width: 0.5),
        ),
      ),
      child: child,
    );
  }
}

// ─── DsAppBar ─────────────────────────────────────────────────────────────────
class DsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBack;
  final Color? accentColor;
  final IconData? titleIcon;

  const DsAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBack = true,
    this.accentColor,
    this.titleIcon,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? Ds.indigo;
    return Container(
      color: Ds.bg,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                if (showBack)
                  _BackBtn(accent: accent),
                if (titleIcon != null) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, accent.withAlpha(180)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(titleIcon, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                ] else if (showBack)
                  const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Ds.text,
                          )),
                      if (subtitle != null) ...[
                        const SizedBox(height: 1),
                        Text(subtitle!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Ds.textSub,
                            )),
                      ],
                    ],
                  ),
                ),
                ...?actions,
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackBtn extends StatelessWidget {
  final Color accent;
  const _BackBtn({required this.accent});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Ds.glass,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Ds.glassBorder, width: 0.5),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 16, color: Ds.textSub),
      ),
    );
  }
}

// ─── AppBarAction (icon button for AppBar) ────────────────────────────────────
class DsAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final int? badge;

  const DsAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: Ds.glass,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Ds.glassBorder, width: 0.5),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 18, color: color ?? Ds.textSub),
            if (badge != null && badge! > 0)
              Positioned(
                top: 6, right: 6,
                child: Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── SectionHeader ────────────────────────────────────────────────────────────
class DsSection extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;

  const DsSection({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          Container(
            width: 4, height: 14,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Ds.indigo, Ds.pink],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Ds.textSub,
              letterSpacing: 0.8,
            ),
          ),
          if (action != null) ...[
            const Spacer(),
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Ds.indigo,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── GradientButton ───────────────────────────────────────────────────────────
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final List<Color>? gradient;
  final IconData? icon;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.gradient,
    this.icon,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient ?? [Ds.indigo, Ds.pink],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Ds.indigo.withAlpha(80),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── DsChip (filter pill) ─────────────────────────────────────────────────────
class DsChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? accent;

  const DsChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final c = accent ?? Ds.indigo;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c : Ds.glass,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c : Ds.glassBorder,
            width: selected ? 0 : 0.5,
          ),
          boxShadow: selected
              ? [BoxShadow(color: c.withAlpha(60), blurRadius: 10, offset: const Offset(0, 3))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: selected ? Colors.white : Ds.textSub),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Ds.textSub,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── StatCard ─────────────────────────────────────────────────────────────────
class DsStatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color accent;
  final String? trend;

  const DsStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.accent,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accent.withAlpha(12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withAlpha(40), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: accent.withAlpha(30),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 14, color: accent),
                ),
                if (trend != null) ...[
                  const Spacer(),
                  Text(trend!,
                      style: TextStyle(fontSize: 10, color: accent, fontWeight: FontWeight.w700)),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w900, color: accent)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: Ds.textSub, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── EmptyState ───────────────────────────────────────────────────────────────
class DsEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? buttonLabel;
  final VoidCallback? onButton;
  final Color? accent;

  const DsEmpty({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.buttonLabel,
    this.onButton,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final c = accent ?? Ds.indigo;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: c.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: c.withAlpha(180)),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Ds.text)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Ds.textSub)),
            ],
            if (buttonLabel != null && onButton != null) ...[
              const SizedBox(height: 24),
              GradientButton(label: buttonLabel!, onTap: onButton!),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Input field (dark styled) ────────────────────────────────────────────────
class DsInput extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final Widget? suffix;
  final void Function(String)? onChanged;
  final TextInputType? keyboardType;
  final int maxLines;

  const DsInput({
    super.key,
    required this.hint,
    this.controller,
    this.prefixIcon,
    this.suffix,
    this.onChanged,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Ds.glass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Ds.glassBorder, width: 0.5),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: Ds.text, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Ds.textMuted, fontSize: 14),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, size: 18, color: Ds.textSub)
              : null,
          suffix: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ─── ListTile styled for dark ─────────────────────────────────────────────────
class DsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const DsTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Ds.text)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: const TextStyle(
                            fontSize: 11, color: Ds.textSub)),
                ],
              ),
            ),
            trailing ??
                const Icon(Icons.chevron_right,
                    size: 16, color: Ds.textMuted),
          ],
        ),
      ),
    );
  }
}
