import 'package:flutter/material.dart';

import '../food_photos.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Food photos are always circles (DESIGN.md §4). No photo → the dashed camera circle.
class FoodPhoto extends StatelessWidget {
  const FoodPhoto({super.key, required this.photoKey, required this.size, this.selected = false});

  final String? photoKey;
  final double size;

  /// The green ring + check of the photo picker.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final asset = FoodPhotos.assetOf(photoKey);
    final circle = SizedBox(
      width: size,
      height: size,
      child: asset == null
          ? _DashedCircle(size: size)
          : ClipOval(child: Image.asset(asset, fit: BoxFit.cover, width: size, height: size)),
    );
    if (!selected) return circle;

    return SizedBox(
      width: size + 8,
      height: size + 8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.green, width: 2.5),
            ),
            child: Padding(padding: const EdgeInsets.all(3), child: circle),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// The "no photo yet" circle: a dashed outline with a camera in the middle.
class _DashedCircle extends StatelessWidget {
  const _DashedCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedCirclePainter(),
      child: Center(
        child: Icon(Icons.photo_camera_rounded, size: size * 0.3, color: AppColors.muted),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    // 20 dashes with a gap the same size, all the way round.
    const dashes = 20;
    const sweep = 3.1415926 * 2 / (dashes * 2);
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 1),
        i * sweep * 2,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) => false;
}

/// The round initial used where there is no photo of a person: order cards, Settings.
class InitialAvatar extends StatelessWidget {
  const InitialAvatar({super.key, required this.name, this.size = 40});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.greenTint, shape: BoxShape.circle),
      child: Text(
        letter,
        style: AppText.body.copyWith(color: AppColors.greenText, fontSize: size * 0.4),
      ),
    );
  }
}
