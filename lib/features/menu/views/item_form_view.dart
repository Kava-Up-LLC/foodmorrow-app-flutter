import 'package:flutter/material.dart';

import '../../../app_services.dart';
import '../../../core/food_photos.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/food_photo.dart';
import '../data/product.dart';
import '../item_form_controller.dart';
import 'photo_library_sheet.dart';

/// Identifies the name field, so a walkthrough types into this screen's field and not into one
/// still on screen from the page it came from.
const itemNameFieldKey = Key('item_name_field');

/// New item / Edit item (screen 08).
class ItemFormView extends StatefulWidget {
  const ItemFormView({super.key, required this.services, this.editing});

  final AppServices services;
  final Product? editing;

  @override
  State<ItemFormView> createState() => _ItemFormViewState();
}

class _ItemFormViewState extends State<ItemFormView> {
  late final ItemFormController _controller = ItemFormController(
    repository: widget.services.menu,
    analytics: widget.services.analytics,
    editing: widget.editing,
  );
  late final TextEditingController _name = TextEditingController(text: _controller.name);

  @override
  void initState() {
    super.initState();
    _name.addListener(() => _controller.setName(_name.text));
  }

  @override
  void dispose() {
    _name.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!await _controller.save() || !mounted) return;
    // Take the messenger before popping: afterwards this context is gone and looking anything
    // up through it is unsafe.
    final messenger = ScaffoldMessenger.of(context);
    final message = _controller.isEditing ? 'Item saved' : 'Added to your menu';
    Navigator.of(context).pop(true);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _remove() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: Shapes.card),
        title: Text('Remove ${widget.editing!.name}?', style: AppText.navTitle),
        content: Text(
          'It leaves your menu and New order. Orders that already have it keep it.',
          style: AppText.bodyRegular.copyWith(color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Keep it', style: AppText.body.copyWith(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Remove', style: AppText.body.copyWith(color: AppColors.orange)),
          ),
        ],
      ),
    );
    if (yes != true) return;
    if (!await _controller.remove() || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final message = '${widget.editing!.name} removed from your menu';
    Navigator.of(context).pop(true);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openLibrary() async {
    final picked = await showPhotoLibrarySheet(context, _controller.photo);
    if (picked != null) _controller.choosePhoto(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            return Column(
              children: [
                ScreenTopBar(title: _controller.title),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(Shapes.side, 10, Shapes.side, 24),
                    children: [
                      if (_controller.failure != null) ...[
                        AlertBanner(
                          failure: _controller.failure!,
                          onRetry: _controller.clearFailure,
                        ),
                        const SizedBox(height: Shapes.gap),
                      ],
                      Center(child: FoodPhoto(photoKey: _controller.photo, size: 170)),
                      const SizedBox(height: 28),
                      Text('Name', style: AppText.navTitle),
                      const SizedBox(height: 10),
                      AppTextField(
                        key: itemNameFieldKey,
                        controller: _name,
                        hint: 'Cookies',
                        autofocus: !_controller.isEditing,
                        maxLength: ItemFormController.maxName,
                        onSubmitted: (_) => _controller.isValid ? _save() : null,
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(child: Text('Photo', style: AppText.navTitle)),
                          GestureDetector(
                            onTap: _openLibrary,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              child: Text(
                                'More photos',
                                style: AppText.body.copyWith(color: AppColors.greenText),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (final key in FoodPhotos.firstFour)
                            GestureDetector(
                              key: ValueKey('pick_photo_$key'),
                              onTap: () => _controller.setPhoto(key),
                              child: FoodPhoto(
                                photoKey: key,
                                size: 66,
                                selected: key == _controller.photo,
                              ),
                            ),
                        ],
                      ),
                      if (_controller.isEditing) ...[
                        const SizedBox(height: 34),
                        Center(
                          child: TextButton.icon(
                            onPressed: _controller.busy ? null : _remove,
                            icon: const Icon(Icons.delete_rounded, size: 20, color: AppColors.orange),
                            label: Text(
                              'Remove from menu',
                              style: AppText.body.copyWith(color: AppColors.orange),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(Shapes.side, 0, Shapes.side, 26),
                  child: PrimaryButton(
                    label: _controller.buttonLabel,
                    busy: _controller.busy,
                    onPressed: _controller.isValid ? _save : null,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
