import 'package:flutter/material.dart';

import '../../data/model/price_tone.dart';
import '../../theme/theme.dart';
import '../common/stock_row.dart';
import 'watchlist_ui_model.dart';

/// 관심 목록의 한 행. 오른쪽에 현재가와 등락을 붙인다.
///
/// 시세를 아직 못 받은 행은 그 자리에 스켈레톤 두 줄이 들어간다.
class WatchlistRow extends StatelessWidget {
  const WatchlistRow({required this.row, super.key});

  final WatchlistRowUi row;

  // 스켈레톤 막대 크기는 이 위젯 한 곳의 상자 크기다. 간격 · 반경 · 아이콘과
  // 달리 다른 화면이 쓸 값이 아니라 토큰으로 올리지 않았다.
  static const double _skeletonPriceWidth = 64;
  static const double _skeletonPriceHeight = 16;
  static const double _skeletonChangeWidth = 48;
  static const double _skeletonChangeHeight = 12;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return StockRow(
      name: row.name,
      marketLabel: row.marketLabel,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: row.isSkeleton
            ? _skeleton(colors, dimens)
            : _quote(colors, dimens),
      ),
    );
  }

  List<Widget> _quote(AppColors colors, AppDimens dimens) {
    return <Widget>[
      Text(
        row.priceLabel!,
        style: AppTypography.body.copyWith(color: colors.textPrimary),
      ),
      SizedBox(height: dimens.gapTextLine),
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
      SizedBox(height: dimens.gapTextLine),
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
