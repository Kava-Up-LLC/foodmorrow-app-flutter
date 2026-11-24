import 'package:flutter/material.dart';

import '../../../app.dart';
import '../../../app_services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/food_photo.dart';
import '../settings_controller.dart';

/// Settings: the business card, the week start, the time zone, Help and the version (screen 09).
class SettingsView extends StatefulWidget {
  const SettingsView({super.key, required this.services, required this.shell});

  final AppServices services;
  final HomeShellState shell;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late final SettingsController _controller = SettingsController(
    repository: widget.services.settings,
    seller: widget.services.seller,
  )..load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _editName() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _BusinessNameDialog(initial: _controller.businessName),
    );
    if (name == null || name.trim().isEmpty) return;
    if (await _controller.saveBusinessName(name)) {
      // Home shows it under the date.
      widget.shell.reloadEverything();
    }
  }

  Future<void> _editWeekStart() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.bg,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Shapes.side, 4, Shapes.side, 12),
              child: Text('Week starts on', style: AppText.title),
            ),
            for (final option in const [('mon', 'Monday'), ('sun', 'Sunday')])
              ListTile(
                title: Text(option.$2, style: AppText.bodyLarge),
                trailing: option.$1 == _controller.weekStart
                    ? const Icon(Icons.check_rounded, color: AppColors.green)
                    : null,
                onTap: () => Navigator.of(context).pop(option.$1),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (picked == null || picked == _controller.weekStart) return;
    if (await _controller.saveWeekStart(picked)) {
      // The day strip in Orders starts on that day from now on.
      widget.shell.reloadEverything();
    }
  }

  void _showHelp() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bg,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Shapes.side, 4, Shapes.side, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Help', style: AppText.title),
              const SizedBox(height: 16),
              for (final tip in const [
                ('Set up your menu once', 'Add what you sell with a photo. Then every order is just + and −.'),
                ('Write orders down as they arrive', 'Tap the green + , pick the day, add the quantities. It takes seconds.'),
                ('Open Home in the morning', 'It tells you everything to make tomorrow, added up across all your orders.'),
              ]) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tip.$1, style: AppText.body),
                      const SizedBox(height: 2),
                      Text(tip.$2, style: AppText.bodyRegular.copyWith(color: AppColors.muted)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: Listenable.merge([_controller, widget.services.seller]),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(Shapes.side, 24, Shapes.side, Shapes.bottomInset),
            children: [
              Text('Settings', style: AppText.title),
              const SizedBox(height: 18),
              if (_controller.failure != null) ...[
                AlertBanner(failure: _controller.failure!, onRetry: _controller.load),
                const SizedBox(height: Shapes.gap),
              ],
              AppCard(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    InitialAvatar(name: _controller.businessName, size: 56),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _controller.businessName,
                            style: AppText.bodyLarge.copyWith(fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text('Shown at the top of Home', style: AppText.small),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _controller.busy ? null : _editName,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                        child: Text('Edit', style: AppText.body.copyWith(color: AppColors.greenText)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Shapes.gap),
              AppCard(
                child: Column(
                  children: [
                    _SettingRow(
                      label: 'Week starts on',
                      value: _controller.startsOnSunday ? 'Sunday' : 'Monday',
                      onTap: _controller.busy ? null : _editWeekStart,
                    ),
                    const Divider(height: 1, thickness: 1, color: AppColors.line, indent: 16, endIndent: 16),
                    // The phone's zone: the app follows it, there is nothing to choose.
                    _SettingRow(label: 'Time zone', value: _timeZone(), onTap: null),
                  ],
                ),
              ),
              const SizedBox(height: Shapes.gap),
              AppCard(
                child: Column(
                  children: [
                    _SettingRow(label: 'Help', value: '', onTap: _showHelp),
                    const Divider(height: 1, thickness: 1, color: AppColors.line, indent: 16, endIndent: 16),
                    _SettingRow(label: 'Version', value: widget.services.appVersion, onTap: null),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Your orders are saved in the cloud, so they are safe if you change phones.',
                style: AppText.bodyRegular.copyWith(color: AppColors.muted),
              ),
            ],
          );
        },
      ),
    );
  }

  /// The phone's own time zone, read-only.
  static String _timeZone() {
    final now = DateTime.now();
    final name = now.timeZoneName;
    final offset = now.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '$name (UTC$sign$hours:$minutes)';
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Expanded(child: Text(label, style: AppText.bodyLarge)),
              if (value.isNotEmpty)
                Flexible(
                  child: Text(
                    value,
                    style: AppText.bodyRegular.copyWith(color: AppColors.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.muted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Asks for the business name. It owns its text controller, so the controller lives exactly as
/// long as the dialog does — disposing it from the caller kills it while the dialog is still
/// animating away.
class _BusinessNameDialog extends StatefulWidget {
  const _BusinessNameDialog({required this.initial});

  final String initial;

  @override
  State<_BusinessNameDialog> createState() => _BusinessNameDialogState();
}

class _BusinessNameDialogState extends State<_BusinessNameDialog> {
  late final TextEditingController _field = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _done() => Navigator.of(context).pop(_field.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: Shapes.card),
      title: Text('Business name', style: AppText.navTitle),
      content: TextField(
        controller: _field,
        autofocus: true,
        maxLength: SettingsController.maxBusinessName,
        textCapitalization: TextCapitalization.words,
        style: AppText.bodyLarge,
        cursorColor: AppColors.green,
        decoration: const InputDecoration(
          hintText: "Ana's Kitchen",
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.green, width: 2),
          ),
        ),
        onSubmitted: (_) => _done(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: AppText.body.copyWith(color: AppColors.muted)),
        ),
        TextButton(
          onPressed: _done,
          child: Text('Save', style: AppText.body.copyWith(color: AppColors.greenText)),
        ),
      ],
    );
  }
}
