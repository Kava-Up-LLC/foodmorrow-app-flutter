import 'package:flutter/material.dart';

import '../../../app_services.dart';
import '../../../core/dates.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/food_photo.dart';
import '../../menu/views/item_form_view.dart';
import '../data/order.dart';
import '../order_draft.dart';
import '../order_form_controller.dart';

/// Identifies the customer field, for the same reason as [itemNameFieldKey].
const customerFieldKey = Key('order_customer_field');

/// New order / Edit order — the screen that has to be done in under 15 seconds (screen 04).
class OrderFormView extends StatefulWidget {
  const OrderFormView({super.key, required this.services, this.editing});

  final AppServices services;
  final Order? editing;

  @override
  State<OrderFormView> createState() => _OrderFormViewState();
}

class _OrderFormViewState extends State<OrderFormView> {
  late final OrderFormController _controller = OrderFormController(
    repository: widget.services.orders,
    menu: widget.services.menu,
    analytics: widget.services.analytics,
    editing: widget.editing,
  )..load();

  late final TextEditingController _customer =
      TextEditingController(text: widget.editing?.customer ?? '');
  late final TextEditingController _note = TextEditingController(text: widget.editing?.note ?? '');

  @override
  void initState() {
    super.initState();
    _customer.addListener(() => _controller.setCustomer(_customer.text));
    _note.addListener(() => _controller.setNote(_note.text));
  }

  @override
  void dispose() {
    _customer.dispose();
    _note.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!await _controller.save() || !mounted) return;
    // The messenger has to be read before the pop; this context does not survive it.
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop(true);
    messenger.showSnackBar(const SnackBar(content: Text('Order saved')));
  }

  Future<void> _pickADay() async {
    final draft = _controller.draft;
    final picked = await showDatePicker(
      context: context,
      initialDate: draft.pickupDate,
      firstDate: draft.firstSelectableDay,
      lastDate: draft.lastSelectableDay,
      helpText: 'Pickup day',
    );
    if (picked != null) _controller.pickDay(picked);
  }

  Future<void> _addFirstItem() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ItemFormView(services: widget.services)),
    );
    if (added == true) await _controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final draft = _controller.draft;
            return Column(
              children: [
                ScreenTopBar(title: _controller.title),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(Shapes.side, 6, Shapes.side, 24),
                    children: [
                      if (_controller.failure != null) ...[
                        AlertBanner(
                          failure: _controller.failure!,
                          onRetry: _controller.loading ? _controller.load : _controller.clearFailure,
                        ),
                        const SizedBox(height: Shapes.gap),
                      ],
                      if (_controller.hasNoMenu)
                        _NoMenuCard(onAdd: _addFirstItem)
                      else ...[
                        AppTextField(
                          key: customerFieldKey,
                          controller: _customer,
                          hint: 'Who is it for?',
                          icon: Icons.person_rounded,
                          autofocus: !_controller.isEditing,
                          maxLength: OrderDraft.maxCustomer,
                        ),
                        const SizedBox(height: 22),
                        Text('Pickup', style: AppText.navTitle),
                        const SizedBox(height: 10),
                        _PickupTiles(
                          draft: draft,
                          onChoose: _controller.choose,
                          onPickADay: _pickADay,
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(child: Text('What they want', style: AppText.navTitle)),
                            Text(draft.itemCountLabel, style: AppText.small),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_controller.loading) ...[
                          const Skeleton(height: 76, radius: 18),
                          const SizedBox(height: 10),
                          const Skeleton(height: 76, radius: 18),
                        ] else
                          for (final product in _controller.products) ...[
                            AppCard(
                              radius: Shapes.tile,
                              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                              child: Row(
                                children: [
                                  FoodPhoto(photoKey: product.photo, size: 52),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      product.name,
                                      style: AppText.bodyLarge,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  QtyStepper(
                                    key: ValueKey('qty_${product.name}'),
                                    value: draft.qtyOf(product.id),
                                    max: OrderDraft.maxQty,
                                    onChanged: (qty) => _controller.setQty(product.id, qty),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        const SizedBox(height: 6),
                        AppTextField(
                          controller: _note,
                          hint: 'Add a note (optional)',
                          icon: Icons.sticky_note_2_rounded,
                          dashed: true,
                          maxLength: OrderDraft.maxNote,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ],
                    ],
                  ),
                ),
                if (!_controller.hasNoMenu)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Shapes.side, 0, Shapes.side, 26),
                    child: PrimaryButton(
                      label: 'Save order',
                      detail: Dates.buttonDay(draft.pickupDate),
                      busy: _controller.busy,
                      onPressed: draft.isValid ? _save : null,
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

/// Today / Tomorrow / Pick a day, as a radio group.
class _PickupTiles extends StatelessWidget {
  const _PickupTiles({required this.draft, required this.onChoose, required this.onPickADay});

  final OrderDraft draft;
  final ValueChanged<PickupChoice> onChoose;
  final VoidCallback onPickADay;

  @override
  Widget build(BuildContext context) {
    final today = Dates.today();
    final tomorrow = Dates.tomorrow();
    return Row(
      children: [
        Expanded(
          child: _PickupTile(
            top: Dates.buttonDay(today),
            label: 'Today',
            selected: draft.choice == PickupChoice.today,
            onTap: () => onChoose(PickupChoice.today),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PickupTile(
            top: Dates.buttonDay(tomorrow),
            label: 'Tomorrow',
            selected: draft.choice == PickupChoice.tomorrow,
            onTap: () => onChoose(PickupChoice.tomorrow),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PickupTile(
            top: draft.choice == PickupChoice.pickADay
                ? Dates.buttonDay(draft.chosenDay)
                : 'Calendar',
            label: 'Pick a day',
            selected: draft.choice == PickupChoice.pickADay,
            onTap: onPickADay,
          ),
        ),
      ],
    );
  }
}

class _PickupTile extends StatelessWidget {
  const _PickupTile({
    required this.top,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String top;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      label: '$label, $top',
      container: true,
      button: true,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? AppColors.greenTint : AppColors.surface,
          borderRadius: Shapes.tile,
          child: InkWell(
            borderRadius: Shapes.tile,
            onTap: onTap,
            child: Container(
              height: 88,
              decoration: BoxDecoration(
                borderRadius: Shapes.tile,
                border: Border.all(
                  color: selected ? AppColors.green : AppColors.line,
                  width: selected ? 2 : 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    size: 20,
                    color: selected ? AppColors.green : AppColors.line,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    top,
                    style: AppText.smaller.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: AppText.body.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// You can't take an order with nothing to sell (HU-03 CA6).
class _NoMenuCard extends StatelessWidget {
  const _NoMenuCard({required this.onAdd});

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
          Text('Add what you sell first', style: AppText.navTitle, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'An order is made of the things on your menu. Add the first one and come back.',
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
