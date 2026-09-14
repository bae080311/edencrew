import 'package:flutter/widgets.dart';

import '../../data/model/price_tone.dart';
import '../../theme/theme.dart';

/// 등락 방향에 맞는 글자색. **상승 = 빨강, 하락 = 파랑** 으로 국내 시장 관행을 따른다.
Color priceToneText(AppColors colors, PriceTone tone) => switch (tone) {
  PriceTone.up => colors.priceUpText,
  PriceTone.down => colors.priceDownText,
  PriceTone.flat => colors.priceFlatText,
};

