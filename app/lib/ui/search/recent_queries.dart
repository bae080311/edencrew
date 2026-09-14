import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../common/app_icon.dart';

/// 검색 전 초기 화면에 뜨는 최근 검색어 칩.
///
/// 시안에 없는 화면이라 정렬 바텀시트 · 토스트와 같은 토큰(`surfaceSunken`,
/// `radiusLg`)을 써서 나머지 화면과 어긋나지 않게 했다.
class RecentQueries extends StatelessWidget {
  const RecentQueries({
    required this.queries,
    required this.onSelected,
    required this.onRemoved,
    required this.onCleared,
    super.key,
  });

  final List<String> queries;
  final ValueChanged<String> onSelected;
  final ValueChanged<String> onRemoved;
  final VoidCallback onCleared;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dimens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                '최근 검색어',
                style: AppTypography.label.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              Semantics(
                button: true,
                label: '최근 검색어 전체 삭제',
                child: GestureDetector(
                  onTap: onCleared,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    '전체 삭제',
                    style: AppTypography.label.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: dimens.space3),
          Wrap(
            spacing: dimens.space2,
            runSpacing: dimens.space2,
            children: queries
                .map(
                  (String query) => _Chip(
                    query: query,
                    onTap: () => onSelected(query),
                    onRemove: () => onRemoved(query),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.query,
    required this.onTap,
    required this.onRemove,
  });

  final String query;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dimens.space3,
          vertical: dimens.chipPaddingVertical,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceSunken,
          borderRadius: BorderRadius.circular(dimens.radiusLg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // 긴 검색어가 칩을 화면 밖으로 밀지 않게 한 줄로 자른다.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                query,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
            ),
            SizedBox(width: dimens.space2),
            Semantics(
              button: true,
              label: '$query 검색어 삭제',
              child: GestureDetector(
                onTap: onRemove,
                behavior: HitTestBehavior.opaque,
                child: AppIcon(
                  AppIcon.x,
                  size: dimens.iconSm,
                  color: colors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
