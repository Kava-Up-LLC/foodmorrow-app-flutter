import 'package:flutter/material.dart';

import '../../../app_services.dart';
import '../../../core/dates.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/shimmer.dart';
import '../../../core/widgets/food_photo.dart';
import '../data/order.dart';
import '../order_detail_controller.dart';
import '../widgets/timeline.dart';
import 'order_form_view.dart';

/// Order details: who, when, what, the note, the timeline and Mark as picked up (screen 06).
class OrderDetailView extends StatefulWidget {
  const OrderDetailView({super.key, required this.services, required this.orderId});

  final AppServices services;
  final String orderId;

  @override
  State<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<OrderDetailView> {
  late final OrderDetailController _controller = OrderDetailController(
    repository: widget.services.orders,
    analytics: widget.services.analytics,
    orderId: widget.orderId,
  )..load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _edit() async {
    final order = _controller.order;
    if (order == null) return;
    clearMessages(context);
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => OrderFormView(services: widget.services, editing: order),
      ),
    );
    if (saved == true) await _controller.reloadAfterEdit();
  }

  Future<void> _delete() async {
    final order = _controller.order;
    if (order == null) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: Shapes.card),
        title: Text("Delete ${order.customer}'s order?", style: AppText.navTitle),
        content: Text(
          'It goes off your list for ${Dates.short(order.pickupDate)}.',
          style: AppText.bodyRegular.copyWith(color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Keep it', style: AppText.body.copyWith(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: AppText.body.copyWith(color: AppColors.orange)),
          ),
        ],
      ),
    );
    if (yes != true) return;
    if (!await _controller.delete() || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop(true);
    messenger.showSnackBar(const SnackBar(content: Text('Order deleted')));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_controller.changed);
      },
      child: Scaffold(
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final order = _controller.order;
              return Column(
                children: [
                  ScreenTopBar(
                    title: 'Order details',
                    trailing: RoundIconButton(
                      icon: Icons.delete_rounded,
                      semanticLabel: 'Delete order',
                      onPressed: order == null || _controller.busy ? null : _delete,
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(Shapes.side, 10, Shapes.side, 24),
                      children: [
                        if (_controller.failure != null) ...[
                          AlertBanner(failure: _controller.failure!, onRetry: _controller.load),
                          const SizedBox(height: Shapes.gap),
                        ],
                        if (order == null) ...[
                          const _OrderDetailSkeleton(),
                        ] else ...[
                          _CustomerCard(order: order, onEdit: _controller.busy ? null : _edit),
                          if (order.hasNote) ...[
                            const SizedBox(height: Shapes.gap),
                            _NoteCard(note: order.note!),
                          ],
                          const SizedBox(height: Shapes.gap),
                          OrderTimeline(order: order),
                        ],
                      ],
                    ),
                  ),
                  if (order != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Shapes.side, 0, Shapes.side, 26),
                      child: order.pickedUp
                          ? SecondaryButton(
                              label: _controller.actionLabel,
                              onPressed: _controller.busy ? null : _controller.togglePickedUp,
                            )
                          : PrimaryButton(
                              label: _controller.actionLabel,
                              icon: Icons.check_rounded,
                              busy: _controller.busy,
                              onPressed: _controller.togglePickedUp,
                            ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The same three blocks the real screen has: who, what, and where the order is up to.
class _OrderDetailSkeleton extends StatelessWidget {
  const _OrderDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SkeletonCard(
          padding: EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  SkeletonCircle(size: 48),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLine(width: 160, height: 16),
                        SizedBox(height: 6),
                        SkeletonLine(width: 120, height: 11),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              SkeletonBox(height: 44, radius: 8),
              SizedBox(height: 16),
              _DetailLineSkeleton(),
              SizedBox(height: 14),
              _DetailLineSkeleton(),
            ],
          ),
        ),
        SizedBox(height: Shapes.gap),
        SkeletonCard(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            children: [
              _TimelineRowSkeleton(),
              SizedBox(height: 16),
              _TimelineRowSkeleton(),
              SizedBox(height: 16),
              _TimelineRowSkeleton(),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailLineSkeleton extends StatelessWidget {
  const _DetailLineSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SkeletonCircle(size: 48),
        SizedBox(width: 14),
        Expanded(child: SkeletonLine(width: 140, height: 15)),
        SkeletonLine(width: 34, height: 15),
      ],
    );
  }
}

class _TimelineRowSkeleton extends StatelessWidget {
  const _TimelineRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SkeletonCircle(size: 20),
        SizedBox(width: 12),
        Expanded(child: SkeletonLine(width: 150, height: 14)),
        SkeletonLine(width: 52, height: 11),
      ],
    );
  }
}

/// The customer, the green pickup strip and the items, as one card (screen 06).
class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.order, required this.onEdit});

  final Order order;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final relative = Dates.relative(order.pickupDate);
    return ClipRRect(
      borderRadius: Shapes.card,
      child: AppCard(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
              child: Row(
                children: [
                  InitialAvatar(name: order.customer, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          order.customer,
                          style: AppText.bodyLarge.copyWith(fontWeight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (order.createdAt != null)
                          Text('Ordered ${Dates.short(order.createdAt!)}', style: AppText.small),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onEdit,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                      child: Text('Edit', style: AppText.body.copyWith(color: AppColors.greenText)),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: AppColors.green,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text('Pickup', style: AppText.body.copyWith(color: Colors.white)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      relative == null
                          ? Dates.short(order.pickupDate)
                          : '${Dates.short(order.pickupDate)} · $relative',
                      style: AppText.body.copyWith(color: Colors.white),
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            for (final line in order.items)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    FoodPhoto(photoKey: line.photo, size: 48),
                    const SizedBox(width: 14),
                    Expanded(child: Text(line.name, style: AppText.bodyLarge)),
                    Text(
                      '×${line.qty}',
                      style: AppText.bodyLarge.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(color: AppColors.noteBg, borderRadius: Shapes.card),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sticky_note_2_rounded, size: 22, color: AppColors.noteIcon),
          const SizedBox(width: 12),
          Expanded(child: Text(note, style: AppText.bodyRegular)),
        ],
      ),
    );
  }
}
