import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// 관심 목록과 검색 결과가 함께 쓰는 종목 행.
///
/// 왼쪽은 `종목명` + `종목코드 · 시장` 두 줄로 고정이고, 오른쪽에 무엇이 붙을지는
/// 화면마다 다르다(시세 · 관심 버튼). 그 자리만 [trailing] 으로 비워 둔다.
class StockRow extends StatelessWidget {
  const StockRow({
    required this.name,
    required this.marketLabel,
    required this.trailing,
    this.highlightStart = -1,
    this.highlightEnd = -1,
    super.key,
  });

  final String name;

  /// `005930 · 코스피`
  final String marketLabel;
  final Widget trailing;

  /// 종목명에서 강조할 구간. 구간 계산은 ViewModel 몫이고 여기서는 잘라 칠하기만 한다.
  /// 강조할 것이 없으면 둘 다 -1.
  final int highlightStart;
  final int highlightEnd;

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
                _name(colors),
                SizedBox(height: dimens.gapTextLine),
                Text(
                  marketLabel,
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
          trailing,
        ],
      ),
    );
  }

  Widget _name(AppColors colors) {
    final TextStyle style = AppTypography.body.copyWith(
      color: colors.textPrimary,
    );

    if (highlightStart < 0) {
      return Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    return Text.rich(
      TextSpan(
        children: <TextSpan>[
          TextSpan(text: name.substring(0, highlightStart)),
          TextSpan(
            text: name.substring(highlightStart, highlightEnd),
            style: TextStyle(color: colors.searchHighlight),
          ),
          TextSpan(text: name.substring(highlightEnd)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}
