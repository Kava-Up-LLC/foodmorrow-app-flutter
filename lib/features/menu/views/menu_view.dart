import 'package:flutter/material.dart';

import '../../../app.dart';
import '../../../app_services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/food_photo.dart';
import '../data/product.dart';
import '../menu_controller.dart';
import 'item_form_view.dart';

/// Identifies the green `+` in the corner, which does the same thing as the empty-state button
/// and so shares its name.
const menuAddItemKey = Key('menu_add_item');

/// Your menu: a 2-column grid of what the seller sells (screen 07).
class MenuView extends StatefulWidget {
  const MenuView({super.key, required this.services, required this.shell});

  final AppServices services;
  final HomeShellState shell;

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  late final MenuListController _controller = MenuListController(repository: widget.services.menu)..load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openItem([Product? product]) async {
    clearMessages(context);
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ItemFormView(services: widget.services, editing: product),
      ),
    );
    // The menu feeds New order and the counts on Home, so everything reads again — and the
    // shell rebuilding this tab is what reads the menu, so there is only one call.
    if (changed == true) widget.shell.reloadEverything();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(Shapes.side, 24, Shapes.side, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_controller.loading ? '' : _controller.countLabel, style: AppText.small),
                                const SizedBox(height: 2),
                                Text('Your menu', style: AppText.title),
                              ],
                            ),
                          ),
                          SquareAddButton(
                            key: menuAddItemKey,
                            onPressed: _openItem,
                            semanticLabel: 'New item',
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (_controller.failure != null) ...[
                        AlertBanner(failure: _controller.failure!, onRetry: _controller.load),
                        const SizedBox(height: Shapes.gap),
                      ],
                    ],
                  ),
                ),
              ),
              if (_controller.loading)
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: Shapes.side),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(child: Skeleton(height: 190)),
                        SizedBox(width: Shapes.gap),
                        Expanded(child: Skeleton(height: 190)),
                      ],
                    ),
                  ),
                )
              else if (_controller.products.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: Shapes.side),
                  sliver: SliverToBoxAdapter(child: _EmptyMenu(onAdd: _openItem)),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    Shapes.side,
                    0,
                    Shapes.side,
                    Shapes.bottomInset,
                  ),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: Shapes.gap,
                      crossAxisSpacing: Shapes.gap,
                      childAspectRatio: 0.86,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => MenuCard(
                        product: _controller.products[i],
                        onTap: () => _openItem(_controller.products[i]),
                      ),
                      childCount: _controller.products.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// One menu item: photo, name, and how many orders from today on include it.
class MenuCard extends StatelessWidget {
  const MenuCard({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = product.photo != null;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FoodPhoto(photoKey: product.photo, size: 96),
          const SizedBox(height: 14),
          Text(
            product.name,
            style: AppText.body.copyWith(fontSize: 15, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            hasPhoto ? product.ordersLabel : 'Add a photo',
            style: AppText.small,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _EmptyMenu extends StatelessWidget {
  const _EmptyMenu({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: AppColors.greenTint, shape: BoxShape.circle),
            child: const Icon(Icons.restaurant_rounded, size: 30, color: AppColors.greenText),
          ),
          const SizedBox(height: 18),
          Text('Nothing on your menu yet', style: AppText.navTitle, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Add what you sell once, and taking an order is just tapping + and −.',
            style: AppText.bodyRegular.copyWith(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          PillButton(label: 'New item', onPressed: onAdd, icon: Icons.add_rounded, height: 48),
        ],
      ),
    );
  }
}
