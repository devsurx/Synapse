import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Shared Synapse chrome — glass cards, section labels, buttons, headers,
/// empty & error states. Using these everywhere is what makes the app
/// feel like one product instead of eight prototypes.

/// Frosted-glass card. The default surface for content blocks.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? accentBorder;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderRadius = AppRadii.card,
    this.accentBorder,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(AppColors.surfaceCard),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color:
                    accentBorder ??
                    Colors.white.withOpacity(AppColors.lineSubtle),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Tiny wide-tracked section label ("NEURAL ARCHIVE").
class SectionLabel extends StatelessWidget {
  final String text;
  final Color? color;

  const SectionLabel(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppType.label.copyWith(color: color));
  }
}

/// Primary CTA button. Full-width pill with haptic tap.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color background;
  final Color foreground;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.background = AppColors.sage,
    this.foreground = Colors.black,
    this.height = 60,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onPressed!();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background.withOpacity(0.35),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 3,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 10),
              Icon(icon, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

/// Centered frosted pill header used as the app-bar title
/// ("NEXUS PLANNER", "ASSESSMENT LAB", ...).
class PillHeader extends StatelessWidget {
  final String title;
  const PillHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(
              color: Colors.white.withOpacity(AppColors.lineSubtle),
            ),
          ),
          child: Text(
            title,
            style: AppType.label.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 4,
            ),
          ),
        ),
      ),
    );
  }
}

/// Standard empty state: ghost icon + headline + hint.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String headline;
  final String hint;

  const EmptyState({
    super.key,
    required this.icon,
    required this.headline,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.sage.withOpacity(0.07),
                border: Border.all(
                  color: Colors.white.withOpacity(AppColors.lineSubtle),
                ),
              ),
              child: Icon(icon, size: 44, color: AppColors.textFaint),
            ),
            const SizedBox(height: 24),
            Text(
              headline,
              textAlign: TextAlign.center,
              style: AppType.label.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: AppType.body.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// Standard error/apology card: tinted icon, headline, message, retry CTA.
class ErrorCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onRetry;
  final Color accent;

  const ErrorCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onRetry,
    this.accent = AppColors.sage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: GlassCard(
          padding: const EdgeInsets.all(32),
          accentBorder: accent.withOpacity(0.18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(0.1),
                ),
                child: Icon(icon, color: accent, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppType.body.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: actionLabel,
                onPressed: onRetry,
                background: accent,
                foreground: Colors.black,
                height: 54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Immersive page scaffold: dark bg + ambient glow orbs + safe content slot.
/// Replaces the one-off wrappers scattered across screens.
class ImmersiveScaffold extends StatelessWidget {
  final Widget child;
  final String? headerTitle;
  final List<Widget>? actions;
  final Widget? leading;
  final Color glowColor;

  const ImmersiveScaffold({
    super.key,
    required this.child,
    this.headerTitle,
    this.actions,
    this.leading,
    this.glowColor = AppColors.sage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.abyss,
      appBar: headerTitle != null
          ? AppBar(
              leading:
                  leading ??
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: AppColors.textFaint,
                    ),
                    onPressed: () => Navigator.maybePop(context),
                  ),
              title: PillHeader(headerTitle!),
              actions: actions,
            )
          : null,
      body: Stack(
        children: [
          Positioned(
            top: -110,
            right: -60,
            child: _orb(300, glowColor.withOpacity(0.1)),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: _orb(260, AppColors.sand.withOpacity(0.06)),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }

  Widget _orb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
        child: const SizedBox.expand(),
      ),
    );
  }
}
