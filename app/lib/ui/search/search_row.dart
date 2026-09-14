import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../common/app_icon.dart';
import '../common/stock_row.dart';
import 'search_ui_model.dart';

/// 검색 결과의 한 행. 오른쪽에 관심 등록 버튼이 붙고, 행을 누르면 상세로 간다.
class SearchRow extends StatelessWidget {
  const SearchRow({
    required this.row,
    required this.onTap,
    required this.onFavoriteTap,
    super.key,
  });

  final SearchRowUi row;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: StockRow(
        name: row.name,
        marketLabel: row.marketLabel,
        highlightStart: row.highlightStart,
        highlightEnd: row.highlightEnd,
        // 아이콘뿐이라 스크린리더에 읽힐 이름이 없다. 상태에 따라 할 일을 알린다.
        trailing: Semantics(
          button: true,
          label: row.isFavorite ? '관심 해제' : '관심 등록',
          child: GestureDetector(
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
        ),
      ),
    );
  }
}
