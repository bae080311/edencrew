import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../common/price_tone_color.dart';
import 'detail_ui_model.dart';

/// 시안 `grid` 의 날짜 칸 폭. 한 위젯의 상자 크기라 토큰으로 올리지 않았다.
const double _dateWidth = 46;

/// 일별 시세 한 줄.
///
/// 1년치가 245행이라 [DailyPriceRow.of] 로 한 줄씩 만들어 `SliverList` 가
/// **보이는 만큼만** 빌드하게 한다. `Column` 으로 한 번에 만들면 위젯 천 개 이상을
/// 한 프레임에 세워 기간을 1년으로 바꿀 때 화면이 눈에 띄게 멈춘다.
class DailyPriceRow extends StatelessWidget {
  const DailyPriceRow({
    required this.date,
    required this.close,
    required this.diff,
    required this.volume,
    required this.dateColor,
    required this.closeColor,
    required this.diffColor,
    this.hasTopBorder = false,
    super.key,
  });

  /// 표의 머리글. 값 대신 컬럼 이름이 들어간 같은 줄이라 별도 타입을 두지 않는다.
  factory DailyPriceRow.header(BuildContext context) {
    final AppColors colors = context.colors;
    return DailyPriceRow(
      date: '날짜',
      close: '종가',
      diff: '등락',
      volume: '거래량',
      dateColor: colors.textSecondary,
      closeColor: colors.textSecondary,
      diffColor: colors.textSecondary,
    );
  }

  /// 행 모델에서 바로 만든다. 색 결정은 여기 한 곳에 모은다.
  factory DailyPriceRow.of(BuildContext context, DailyPriceRowUi row) {
    final AppColors colors = context.colors;
    return DailyPriceRow(
      date: row.dateLabel,
      close: row.closeLabel,
      diff: row.diffLabel,
      volume: row.volumeLabel,
      dateColor: colors.textSecondary,
      closeColor: colors.textPrimary,
      diffColor: priceToneText(colors, row.tone),
      hasTopBorder: true,
    );
  }

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
      padding: EdgeInsets.symmetric(vertical: dimens.tableRowPaddingVertical),
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
