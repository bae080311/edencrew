import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../common/price_tone_color.dart';
import 'detail_view_model.dart';

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
          child: Text(
            viewModel.priceLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.displayPrice.copyWith(
              color: colors.textPrimary,
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
