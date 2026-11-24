import 'package:flutter/material.dart';

import '../../../core/dates.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../data/order.dart';

/// Where an order is up to: saved → on the list to make → picked up.
class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final today = Dates.today();
    final pickup = order.pickupDate;

    // "On the list to make" is done once the pickup day has arrived; it is where we are now when
    // the day is still ahead.
    final makeReached = !pickup.isAfter(today);

    final steps = <_Step>[
      _Step(
        label: 'Order saved',
        date: order.createdAt == null ? '' : Dates.dayAndMonth(order.createdAt!),
        state: _StepState.done,
      ),
      _Step(
        label: 'On the list to make',
        date: Dates.buttonDay(pickup),
        state: order.pickedUp
            ? _StepState.done
            : (makeReached ? _StepState.done : _StepState.now),
      ),
      _Step(
        label: 'Picked up',
        date: order.pickedUpAt == null
            ? Dates.buttonDay(pickup)
            : Dates.dayAndMonth(order.pickedUpAt!),
        state: order.pickedUp ? _StepState.done : _StepState.next,
      ),
    ];

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _TimelineRow(step: steps[i]),
          ],
        ],
      ),
    );
  }
}

enum _StepState { done, now, next }

class _Step {
  const _Step({required this.label, required this.date, required this.state});

  final String label;
  final String date;
  final _StepState state;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step});

  final _Step step;

  @override
  Widget build(BuildContext context) {
    final pending = step.state == _StepState.next;
    return Row(
      children: [
        SizedBox(width: 20, height: 20, child: _Dot(state: step.state)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            step.label,
            style: AppText.body.copyWith(color: pending ? AppColors.muted : AppColors.ink),
          ),
        ),
        Text(step.date, style: AppText.small),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.state});

  final _StepState state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      _StepState.done => const DecoratedBox(
          decoration: BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
          child: Icon(Icons.check_rounded, size: 14, color: Colors.white),
        ),
      _StepState.now => DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.green, width: 2.5),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
            ),
          ),
        ),
      _StepState.next => DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.line, width: 2),
          ),
        ),
    };
  }
}
