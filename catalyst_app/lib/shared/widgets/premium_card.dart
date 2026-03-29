import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:catalyst_app/shared/widgets/animated_pressable.dart';

/// A premium‑looking card with glass‑morphism, animated shadow and press scaling.
class PremiumCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double elevation;
  final EdgeInsetsGeometry? margin;
  final Clip clipBehavior;

  const PremiumCard({
    super.key,
    required this.child,
    this.onTap,
    this.elevation = 2.0,
    this.margin,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    // Glass‑morphism background
    final glass = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
          ),
          child: child,
        ),
      ),
    );

    // Animated shadow that pulses on hover / long‑press (desktop & mobile)
    final animatedCard = AnimatedPressable(
      onTap: onTap,
      pressedScale: 1.02,
      child: Card(
        margin: margin,
        elevation: elevation,
        clipBehavior: clipBehavior,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: glass,
      ),
    )
        .animate()
        .boxShadow(
          begin: const BoxShadow(color: Colors.transparent),
          end: BoxShadow(
            color: Colors.blueAccent.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
          duration: 800.ms,
          curve: Curves.easeInOut,
        );

    return animatedCard;
  }
}
