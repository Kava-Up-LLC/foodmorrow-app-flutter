import 'package:flutter/material.dart';

import '../../../app_services.dart';
import '../../../core/appambit/analytics.dart';
import '../../../core/dates.dart';
import '../../../core/loadable.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../data/order.dart';
import '../data/orders_repository.dart';
import '../widgets/order_card.dart';

/// Search by customer, in the orders from today on. Pops the id of the order that was tapped.
class SearchController extends LoadableController {
  SearchController({required this.repository, required this.analytics});

  final OrdersRepository repository;
  final Analytics analytics;

  String query = '';
  List<SearchHit> results = const [];

  /// Nothing to load until something is typed.
  @override
  Future<void> fetch() async {}

  Future<void> search(String value) async {
    query = value.trim();
    if (query.isEmpty) {
      results = const [];
      clearFailure();
      refresh();
      return;
    }
    await runWrite(() async {
      final found = await repository.search(query);
      // Another keystroke may have landed while this was in the air; only the newest wins.
      if (query.isNotEmpty) results = found;
    });
    analytics.track(Events.searchUsed, {'results': '${results.length}'});
  }
}

class SearchView extends StatefulWidget {
  const SearchView({super.key, required this.services});

  final AppServices services;

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  late final SearchController _controller = SearchController(
    repository: widget.services.orders,
    analytics: widget.services.analytics,
  );
  final _field = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    _controller.dispose();
    super.dispose();
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
                const ScreenTopBar(title: 'Search'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(Shapes.side, 0, Shapes.side, 16),
                  child: AppTextField(
                    controller: _field,
                    hint: 'Customer name',
                    icon: Icons.search_rounded,
                    autofocus: true,
                    maxLength: 40,
                    onSubmitted: _controller.search,
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(Shapes.side, 0, Shapes.side, 24),
                    children: [
                      if (_controller.failure != null) ...[
                        AlertBanner(
                          failure: _controller.failure!,
                          onRetry: () => _controller.search(_field.text),
                        ),
                        const SizedBox(height: Shapes.gap),
                      ],
                      if (_controller.busy)
                        const Skeleton(height: 150)
                      else if (_controller.query.isEmpty)
                        Text(
                          'Type a name to find upcoming orders.',
                          style: AppText.bodyRegular.copyWith(color: AppColors.muted),
                        )
                      else if (_controller.results.isEmpty)
                        Text(
                          'Nobody by that name has an order coming up.',
                          style: AppText.bodyRegular.copyWith(color: AppColors.muted),
                        )
                      else
                        for (final hit in _controller.results) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6, top: 6),
                            child: Text(_dayLabel(hit.date), style: AppText.small),
                          ),
                          OrderCard(
                            order: hit.order,
                            onTap: () => Navigator.of(context).pop(hit.order.id),
                          ),
                          const SizedBox(height: Shapes.gap),
                        ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _dayLabel(DateTime day) {
    final relative = Dates.relative(day);
    return relative == null ? Dates.short(day) : '${Dates.short(day)} · $relative';
  }
}
