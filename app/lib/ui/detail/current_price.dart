import 'package:flutter/material.dart';

import '../../core/format.dart' as fmt;
import '../../theme/theme.dart';
import '../common/price_tone_color.dart';
import 'detail_view_model.dart';

/// 현재가 숫자가 이전 값에서 새 값으로 흐르는 시간.
const Duration _count = Duration(milliseconds: 500);

/// 현재가와 그 옆의 등락(`▼ 400 (-0.22%)`).
///
/// 글자가 커지면 둘 다 줄어들 수 있게 각각 [Flexible] 로 둔다.
class CurrentPrice extends StatelessWidget {
  const CurrentPrice({required this.viewModel, super.key});

  final DetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Flexible(
          // 값이 바뀌는 구간을 이어서 보여준다. 숫자가 툭 갈리면 무엇이 얼마나
          // 바뀌었는지 남지 않는다. 시세를 못 받았으면 보간할 값이 없어 그대로 쓴다.
          child: TweenAnimationBuilder<double>(
            // begin 은 첫 등장에서만 쓰인다 — 0 부터 올라온다. 이후 값이 바뀌면
            // 위젯이 직전 값에서 새 end 까지 이어서 흐른다.
            tween: Tween<double>(
              begin: 0,
              end: (viewModel.price ?? 0).toDouble(),
            ),
            duration: _count,
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double value, Widget? _) => Text(
              viewModel.price == null
                  ? viewModel.priceLabel
                  : fmt.thousands(value.round()),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.displayPrice.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
        ),
        SizedBox(width: context.dimens.space2),
        Flexible(
          child: Text(
            viewModel.changeLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(
              color: priceToneText(colors, viewModel.tone),
            ),
          ),
        ),
      ],
    );
  }
}
