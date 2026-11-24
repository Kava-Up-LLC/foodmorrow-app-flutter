import 'package:flutter/material.dart';

import '../../../core/food_photos.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/food_photo.dart';

/// "More photos": every photo in the built-in library. Returns the key that was picked, or null.
Future<String?> showPhotoLibrarySheet(BuildContext context, String? selected) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.bg,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _PhotoLibrarySheet(selected: selected),
  );
}

class _PhotoLibrarySheet extends StatelessWidget {
  const _PhotoLibrarySheet({required this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Shapes.side, 4, Shapes.side, 10),
              child: Text('Pick a photo', style: AppText.title),
            ),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(Shapes.side, 6, Shapes.side, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 18,
                  childAspectRatio: 1,
                ),
                itemCount: FoodPhotos.keys.length,
                itemBuilder: (context, i) {
                  final key = FoodPhotos.keys[i];
                  return GestureDetector(
                    onTap: () => Navigator.of(context).pop(key),
                    child: Center(
                      child: FoodPhoto(photoKey: key, size: 86, selected: key == selected),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
