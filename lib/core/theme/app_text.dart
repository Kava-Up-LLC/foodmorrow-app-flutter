import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The type scale (DESIGN.md §3). Plus Jakarta Sans, tabular figures for every number.
abstract final class AppText {
  static const family = 'Plus Jakarta Sans';
  static const _figures = <FontFeature>[FontFeature.tabularFigures()];

  static const TextStyle _base = TextStyle(
    fontFamily: family,
    color: AppColors.ink,
    fontFeatures: _figures,
  );

  /// Welcome title.
  static final display = _base.copyWith(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    height: 1.15,
  );

  /// "52 things to make", on the Home banner.
  static final bannerNumber = _base.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    height: 1.15,
    color: Colors.white,
  );

  /// Tab screen titles: Orders, Your menu, Settings.
  static final title = _base.copyWith(fontSize: 24, fontWeight: FontWeight.w800);

  /// The business name on Home.
  static final greeting = _base.copyWith(fontSize: 21, fontWeight: FontWeight.w800);

  /// Centered title of a pushed screen, and section headers.
  static final navTitle = _base.copyWith(fontSize: 19, fontWeight: FontWeight.w800);

  /// The quantity on a Home product card.
  static final qtyBig = _base.copyWith(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
    color: AppColors.greenText,
  );

  /// Names in lists and cards.
  static final body = _base.copyWith(fontSize: 16, fontWeight: FontWeight.w700);
  static final bodyLarge = _base.copyWith(fontSize: 17, fontWeight: FontWeight.w700);

  /// Paragraphs.
  static final bodyRegular = _base.copyWith(fontSize: 16, fontWeight: FontWeight.w500);

  /// Subtitles, counts, dates and chips.
  static final small = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.muted,
  );
  static final smaller = _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.muted,
  );
}
