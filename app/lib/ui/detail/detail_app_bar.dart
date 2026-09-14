import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../common/app_icon.dart';
import 'detail_view_model.dart';

/// 종목상세 상단 바. 뒤로 가기 · 종목명 · `종목코드 · 시장` · 관심 등록 버튼.
class DetailAppBar extends StatelessWidget {
  const DetailAppBar({required this.viewModel, super.key});

  final DetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space4,
        vertical: dimens.appBarPaddingVertical,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors.borderSubtle,
            width: dimens.borderHairline,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          Semantics(
            button: true,
            label: '뒤로 가기',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: AppIcon(
                AppIcon.back,
                size: dimens.iconMd,
                color: colors.textSecondary,
              ),
            ),
          ),
          SizedBox(width: dimens.space3),
          Expanded(child: _identity(colors, dimens)),
          SizedBox(width: dimens.space3),
          Semantics(
            button: true,
            enabled: viewModel.canToggleFavorite,
            label: viewModel.isFavorite ? '관심 해제' : '관심 등록',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              // 조회 중 · 실패 상태에서는 누를 수 없다. 새로고침 버튼과 같은 방식이다.
              onTap: viewModel.canToggleFavorite
                  ? viewModel.toggleFavorite
                  : null,
              child: AppIcon(
                viewModel.isFavorite ? AppIcon.starFill : AppIcon.star,
                size: dimens.iconFavorite,
                color: _favoriteColor(colors),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _identity(AppColors colors, AppDimens dimens) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        viewModel.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.body.copyWith(color: colors.textPrimary),
      ),
      SizedBox(height: dimens.gapTextLine),
      Text(
        viewModel.marketLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.caption.copyWith(color: colors.textSecondary),
      ),
    ],
  );

  Color _favoriteColor(AppColors colors) {
    if (!viewModel.canToggleFavorite) return colors.textDisabled;
    return viewModel.isFavorite
        ? colors.favoriteActive
        : colors.favoriteInactive;
  }
}
