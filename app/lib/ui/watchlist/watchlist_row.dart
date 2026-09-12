import 'package:flutter/material.dart';

import '../../data/model/price_tone.dart';
import '../../theme/theme.dart';
import 'watchlist_ui_model.dart';

/// 관심 목록의 한 행.
///
/// 시세를 아직 못 받은 행은 가격 자리에 스켈레톤 두 줄이 들어간다.
class WatchlistRow extends StatelessWidget {
  const WatchlistRow({required this.row, super.key});

  final WatchlistRowUi row;

  // Figma 레이어 값 — `Scale` 컬렉션에 없어 토큰으로 옮기지 않았다.
  static const double _identityGap = 2;
  static const double _skeletonPriceWidth = 64;
  static const double _skeletonPriceHeight = 16;
  static const double _skeletonChangeWidth = 48;
  static const double _skeletonChangeHeight = 12;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Container(
      constraints: BoxConstraints(minHeight: dimens.rowMinHeight),
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space4,
        vertical: dimens.space3,
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
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  row.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: _identityGap),
                Text(
                  row.marketLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: dimens.space3),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: row.isSkeleton
                ? _skeleton(colors, dimens)
                : _quote(colors),
          ),
        ],
      ),
    );
  }

  List<Widget> _quote(AppColors colors) {
    return <Widget>[
      Text(
        row.priceLabel!,
        style: AppTypography.body.copyWith(color: colors.textPrimary),
      ),
      const SizedBox(height: _identityGap),
      Text(
        row.changeLabel!,
        style: AppTypography.caption.copyWith(color: _toneColor(colors)),
      ),
    ];
  }

  List<Widget> _skeleton(AppColors colors, AppDimens dimens) {
    return <Widget>[
      _SkeletonBar(
        width: _skeletonPriceWidth,
        height: _skeletonPriceHeight,
        color: colors.feedbackSkeleton,
        radius: dimens.radiusSm,
      ),
      const SizedBox(height: _identityGap),
      _SkeletonBar(
        width: _skeletonChangeWidth,
        height: _skeletonChangeHeight,
        color: colors.feedbackSkeleton,
        radius: dimens.radiusSm,
      ),
    ];
  }

  /// 상승 = 빨강, 하락 = 파랑. 국내 시장 관행이다.
  Color _toneColor(AppColors colors) {
    switch (row.tone) {
      case PriceTone.up:
        return colors.priceUpText;
      case PriceTone.down:
        return colors.priceDownText;
      case PriceTone.flat:
        return colors.priceFlatText;
    }
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({
    required this.width,
    required this.height,
    required this.color,
    required this.radius,
  });

  final double width;
  final double height;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
