import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Loading placeholders (DESIGN.md §7: "lists load with skeletons, never a full-screen spinner").
///
/// A screen wraps its placeholders in one [Shimmer] so the whole group sweeps together, and builds
/// them out of [SkeletonBox], [SkeletonLine] and [SkeletonCircle] in the shape of the real content
/// — so when the answer arrives nothing jumps.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  // Built here rather than lazily: with "reduce motion" on, build() never reads it, and a lazy
  // field would then be created inside dispose() — on an element that is already gone.
  late final AnimationController _sweep;

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // With "reduce motion" the sweep does not just go unpainted — it never runs, so nothing is
    // burning frames behind a still picture.
    if (MediaQuery.disableAnimationsOf(context)) {
      _sweep.stop();
    } else if (!_sweep.isAnimating) {
      _sweep.repeat();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // "Reduce motion" means no sweep: the placeholders stay still.
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;

    return AnimatedBuilder(
      animation: _sweep,
      child: widget.child,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [AppColors.skeleton, AppColors.skeletonHighlight, AppColors.skeleton],
          stops: const [0.25, 0.5, 0.75],
          transform: _Sweep(_sweep.value),
        ).createShader(bounds),
        child: child,
      ),
    );
  }
}

/// Slides the gradient from off the left edge to off the right edge, once per turn.
class _Sweep extends GradientTransform {
  const _Sweep(this.t);

  final double t;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (t * 3 - 1.5), 0, 0);
}

/// A filled block in the shape of a card.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.radius = 22,
  });

  final double height;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.skeleton,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A stand-in for a line of text.
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({super.key, required this.width, this.height = 12});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => SkeletonBox(height: height, width: width, radius: 6);
}

/// A stand-in for one of the round food photos.
class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: AppColors.skeleton, shape: BoxShape.circle),
    );
  }
}

/// A real white card with placeholders inside, which is what most of the app is made of.
///
/// The card shimmers its *contents*, not itself: a [Shimmer] around the whole card would paint
/// the white background too and flatten it into one grey blob.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, required this.child, this.padding, this.radius = 22});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppColors.shadow,
      ),
      child: Shimmer(child: child),
    );
  }
}
