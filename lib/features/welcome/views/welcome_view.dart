import 'package:flutter/material.dart';

import '../../../app.dart';
import '../../../app_services.dart';
import '../../../core/appambit/analytics.dart';
import '../../../core/food_photos.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/food_photo.dart';
import '../../menu/views/item_form_view.dart';

/// First open: what the app is for, and the way in (screen 01). Shown once per phone.
class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key, required this.services});

  final AppServices services;

  Future<void> _start(BuildContext context) async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ItemFormView(services: services)),
    );
    if (added != true || !context.mounted) return;

    await services.store.markWelcomeDone();
    services.analytics.track(Events.welcomeDone);
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeShell(services: services)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Shapes.side, 0, Shapes.side, 26),
          child: Column(
            children: [
              const Expanded(flex: 5, child: _PhotoCollage()),
              Text(
                'Know today what\nyou cook tomorrow',
                style: AppText.display,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Text(
                'Write down orders as they come in. Foodmorrow adds them up so you know what to '
                'make each day.',
                style: AppText.bodyRegular.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              PrimaryButton(label: 'Add what you sell', onPressed: () => _start(context)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The four food photos at the top, overlapping the way the screen shows them.
class _PhotoCollage extends StatelessWidget {
  const _PhotoCollage();

  @override
  Widget build(BuildContext context) {
    final keys = FoodPhotos.firstFour;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        // Fractions of the box, so the collage keeps its shape on a small or a big phone.
        return Stack(
          children: [
            Positioned(left: w * 0.05, top: h * 0.10, child: FoodPhoto(photoKey: keys[3], size: w * 0.29)),
            Positioned(left: w * 0.26, top: h * 0.00, child: FoodPhoto(photoKey: keys[0], size: w * 0.56)),
            Positioned(left: w * 0.00, top: h * 0.45, child: FoodPhoto(photoKey: keys[2], size: w * 0.42)),
            Positioned(left: w * 0.56, top: h * 0.54, child: FoodPhoto(photoKey: keys[1], size: w * 0.38)),
          ],
        );
      },
    );
  }
}
