import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import 'app_icon.dart';

/// 목록이 비었을 때 화면 가운데에 놓이는 안내. 관심 · 검색 전 · 검색 결과 없음이 함께 쓴다.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
  });

  final String icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: dimens.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppIcon(icon, size: dimens.iconEmpty, color: colors.textTertiary),
            SizedBox(height: dimens.space3),
            Text(
              title,
              style: AppTypography.title.copyWith(color: colors.textSecondary),
            ),
            SizedBox(height: dimens.space3),
            Text(
              description,
              textAlign: TextAlign.center,
              // 검색어가 그대로 들어가는 문구가 있어 길이를 장담할 수 없다.
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
