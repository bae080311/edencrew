import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../common/price_tone_color.dart';
import 'detail_ui_model.dart';

/// 시안 `grid` 의 날짜 칸 폭. 한 위젯의 상자 크기라 토큰으로 올리지 않았다.
const double _dateWidth = 46;

/// `날짜 · 종가 · 등락 · 거래량` 네 컬럼의 일별 시세 표.
///
/// 1년치 245행을 한 번에 만든다. 무한 스크롤(선택 항목)을 붙이게 되면 그때 `SliverList` 로 바꾼다.
class DailyPriceTable extends StatelessWidget {
  const DailyPriceTable({required this.rows, super.key});

  final List<DailyPriceRowUi> rows;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return Column(
      children: <Widget>[
        _Row(
          date: '날짜',
          close: '종가',
          diff: '등락',
          volume: '거래량',
          dateColor: colors.textSecondary,
          closeColor: colors.textSecondary,
          diffColor: colors.textSecondary,
        ),
        for (final DailyPriceRowUi row in rows)
          _Row(
            date: row.dateLabel,
            close: row.closeLabel,
            diff: row.diffLabel,
            volume: row.volumeLabel,
            dateColor: colors.textSecondary,
            closeColor: colors.textPrimary,
            diffColor: priceToneText(colors, row.tone),
            hasTopBorder: true,
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.date,
    required this.close,
    required this.diff,
    required this.volume,
    required this.dateColor,
    required this.closeColor,
    required this.diffColor,
    this.hasTopBorder = false,
  });

  final String date;
  final String close;
  final String diff;
  final String volume;
  final Color dateColor;
  final Color closeColor;
  final Color diffColor;
  final bool hasTopBorder;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: dimens.tableRowPaddingVertical,
      ),
      decoration: hasTopBorder
          ? BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colors.borderSubtle,
                  width: dimens.borderHairline,
                ),
              ),
            )
          : null,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: _dateWidth,
            child: _text(date, dateColor, TextAlign.left),
          ),
          SizedBox(width: dimens.space2),
          Expanded(child: _text(close, closeColor, TextAlign.right)),
          SizedBox(width: dimens.space2),
          Expanded(child: _text(diff, diffColor, TextAlign.right)),
          SizedBox(width: dimens.space2),
          Expanded(child: _text(volume, colors.textSecondary, TextAlign.right)),
        ],
      ),
    );
  }

  Widget _text(String value, Color color, TextAlign align) => Text(
    value,
    textAlign: align,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: AppTypography.caption.copyWith(color: color),
  );
}
