import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../common/app_icon.dart';
import '../common/stock_row.dart';
import 'search_ui_model.dart';

/// 검색 결과의 한 행. 오른쪽에 관심 등록 버튼이 붙는다.
class SearchRow extends StatelessWidget {
  const SearchRow({required this.row, required this.onFavoriteTap, super.key});

  final SearchRowUi row;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return StockRow(
      name: row.name,
      marketLabel: row.marketLabel,
      highlightStart: row.highlightStart,
      highlightEnd: row.highlightEnd,
      trailing: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onFavoriteTap,
        child: AppIcon(
          row.isFavorite ? AppIcon.starFill : AppIcon.star,
          size: context.dimens.iconFavorite,
          color: row.isFavorite
              ? colors.favoriteActive
              : colors.favoriteInactive,
        ),
      ),
    );
  }
}
