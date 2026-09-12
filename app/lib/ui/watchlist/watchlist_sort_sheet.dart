import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../common/app_icon.dart';
import 'watchlist_sort.dart';

// Figma 레이어 값 — `Scale` 컬렉션에 없다.
const double _sheetRadius = 16;
const double _titleHeight = 64;
const double _itemHeight = 56;
const double _checkSize = 24;

/// 정렬 바텀시트를 열고 고른 기준을 돌려준다. 그냥 닫으면 null.
///
/// 딤은 `showModalBottomSheet` 기본값(검정 54%)을 쓴다. 시안은 50% 지만
/// 토큰에 없는 색이라 프레임워크 기본값을 그대로 두는 쪽을 택했다.
Future<WatchlistSort?> showWatchlistSortSheet(
  BuildContext context, {
  required WatchlistSort current,
}) {
  return showModalBottomSheet<WatchlistSort>(
    context: context,
    backgroundColor: context.colors.surfaceOverlay,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(_sheetRadius)),
    ),
    builder: (BuildContext sheetContext) =>
        _SortSheet(current: current, onSelected: Navigator.of(sheetContext).pop),
  );
}

class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.current, required this.onSelected});

  final WatchlistSort current;
  final ValueChanged<WatchlistSort> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            height: _titleHeight,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: dimens.space6),
            child: Text(
              '정렬',
              style: AppTypography.title.copyWith(color: colors.textPrimary),
            ),
          ),
          for (final WatchlistSort sort in WatchlistSort.values)
            _SortItem(
              sort: sort,
              isSelected: sort == current,
              onTap: () => onSelected(sort),
            ),
        ],
      ),
    );
  }
}

class _SortItem extends StatelessWidget {
  const _SortItem({
    required this.sort,
    required this.isSelected,
    required this.onTap,
  });

  final WatchlistSort sort;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: _itemHeight),
        padding: EdgeInsets.symmetric(
          horizontal: dimens.space6,
          vertical: dimens.space3,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                sort.label,
                style: AppTypography.body.copyWith(
                  color: isSelected ? colors.textPrimary : colors.textSecondary,
                ),
              ),
            ),
            if (isSelected)
              AppIcon(
                AppIcon.check,
                size: _checkSize,
                color: colors.textPrimary,
              ),
          ],
        ),
      ),
    );
  }
}
