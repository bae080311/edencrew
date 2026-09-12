import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// 시가 · 고가 · 저가 · 거래량 · 시가총액을 담는 요약 카드.
///
/// 시안은 셀 폭을 115 · 176.5 로 고정하지만, 좁은 기기에서도 한 줄에 들어가도록
/// 3칸 · 2칸을 각각 균등 분배한다.
class QuoteSummaryCard extends StatelessWidget {
  const QuoteSummaryCard({
    required this.open,
    required this.high,
    required this.low,
    required this.volume,
    required this.marketCap,
    super.key,
  });

  final String open;
  final String high;
  final String low;
  final String volume;
  final String marketCap;

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _Cell(label: '시가', value: open),
            ),
            SizedBox(width: dimens.space2),
            Expanded(
              child: _Cell(label: '고가', value: high),
            ),
            SizedBox(width: dimens.space2),
            Expanded(
              child: _Cell(label: '저가', value: low),
            ),
          ],
        ),
        SizedBox(height: dimens.space2),
        Row(
          children: <Widget>[
            Expanded(
              child: _Cell(label: '거래량', value: volume),
            ),
            SizedBox(width: dimens.space2),
            Expanded(
              child: _Cell(label: '시가총액', value: marketCap),
            ),
          ],
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dimens.cardPaddingHorizontal,
        vertical: dimens.cardPaddingVertical,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: BorderRadius.circular(dimens.radiusMd),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
          SizedBox(height: dimens.gapCardLabel),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}
