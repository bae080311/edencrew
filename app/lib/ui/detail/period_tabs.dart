import 'package:flutter/material.dart';

import '../../data/model/chart_period.dart';
import '../../theme/theme.dart';

/// 차트와 일별 시세의 기간을 고르는 탭 4개.
class PeriodTabs extends StatelessWidget {
  const PeriodTabs({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final ChartPeriod selected;
  final ValueChanged<ChartPeriod> onChanged;

  /// 표시 문자열은 View 몫이라 enum 이 아니라 여기에 둔다.
  static const Map<ChartPeriod, String> _labels = <ChartPeriod, String>{
    ChartPeriod.oneMonth: '1개월',
    ChartPeriod.threeMonths: '3개월',
    ChartPeriod.sixMonths: '6개월',
    ChartPeriod.oneYear: '1년',
  };

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;

    return Row(
      children: <Widget>[
        for (final MapEntry<ChartPeriod, String> entry
            in _labels.entries) ...<Widget>[
          if (entry.key != ChartPeriod.oneMonth) SizedBox(width: dimens.space1),
          Expanded(
            child: _Chip(
              label: entry.value,
              isSelected: entry.key == selected,
              onTap: () => onChanged(entry.key),
            ),
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(
          horizontal: dimens.space3,
          vertical: dimens.chipPaddingVertical,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentBg : null,
          borderRadius: BorderRadius.circular(dimens.radiusMd),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          // 같은 13/18 이지만 시안의 탭 라벨은 Regular 다.
          style: AppTypography.label.copyWith(
            fontWeight: AppTypography.regular,
            color: isSelected ? colors.accentDefault : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
