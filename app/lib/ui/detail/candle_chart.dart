import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/model/daily_price.dart';
import '../../data/model/price_tone.dart';
import '../../theme/theme.dart';

/// 일별 시세를 캔들로 그린다. 축 라벨 · 거래량 바 · 크로스헤어는 과제의 선택 항목이라 넣지 않았다.
class CandleChart extends StatelessWidget {
  const CandleChart({required this.prices, super.key});

  /// 최신 거래일이 먼저 온다. 왼쪽이 과거가 되도록 뒤에서부터 그린다.
  final List<DailyPrice> prices;

  /// 시안 `Chart` 프레임 높이. 이 화면 밖에서 쓰지 않아 토큰으로 올리지 않았다.
  static const double _height = 200;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return SizedBox(
      height: _height,
      width: double.infinity,
      child: CustomPaint(
        painter: _CandlePainter(
          prices: prices,
          up: colors.chartLineUp,
          down: colors.chartLineDown,
          flat: colors.chartLineFlat,
          wick: colors.chartBaseline,
        ),
      ),
    );
  }
}

class _CandlePainter extends CustomPainter {
  _CandlePainter({
    required this.prices,
    required this.up,
    required this.down,
    required this.flat,
    required this.wick,
  });

  final List<DailyPrice> prices;
  final Color up;
  final Color down;
  final Color flat;
  final Color wick;

  /// 캔들 사이 간격은 시안 값(1.2). 심지 굵기는 시안이 0.3 이지만 1년치 245개를
  /// 그리면 사라져서 최소 굵기를 따로 잡았다.
  static const double _gap = 1.2;
  static const double _minWidth = 0.8;

  /// 맨 위 · 맨 아래 캔들의 심지가 잘리지 않을 만큼만 띄운다.
  static const double _inset = 4;

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.isEmpty) return;

    int lowest = prices.first.low;
    int highest = prices.first.high;
    for (final DailyPrice price in prices) {
      lowest = math.min(lowest, price.low);
      highest = math.max(highest, price.high);
    }

    final double span = (highest - lowest).toDouble();
    final double usable = math.max(size.height - _inset * 2, 1);
    // 구간 전체가 같은 값이면 나눌 것이 없다. 가운데 한 줄로 그린다.
    double y(int value) => span == 0
        ? size.height / 2
        : _inset + usable * (highest - value) / span;

    final double slot = size.width / prices.length;
    final double bodyWidth = math.max(slot - _gap, _minWidth);
    final Paint wickPaint = Paint()
      ..color = wick
      ..strokeWidth = math.max(_minWidth, bodyWidth * 0.2);

    for (int i = 0; i < prices.length; i++) {
      final DailyPrice price = prices[prices.length - 1 - i];
      final double centerX = slot * (i + 0.5);

      canvas.drawLine(
        Offset(centerX, y(price.high)),
        Offset(centerX, y(price.low)),
        wickPaint,
      );

      final double top = y(math.max(price.open, price.close));
      final double bottom = y(math.min(price.open, price.close));
      canvas.drawRect(
        Rect.fromLTRB(
          centerX - bodyWidth / 2,
          top,
          centerX + bodyWidth / 2,
          // 시가 = 종가면 높이가 0 이라 아무것도 안 보인다.
          math.max(bottom, top + _minWidth),
        ),
        Paint()..color = _colorOf(price.candleTone),
      );
    }
  }

  Color _colorOf(PriceTone tone) => switch (tone) {
    PriceTone.up => up,
    PriceTone.down => down,
    PriceTone.flat => flat,
  };

  @override
  bool shouldRepaint(_CandlePainter oldDelegate) =>
      oldDelegate.prices != prices ||
      oldDelegate.up != up ||
      oldDelegate.down != down ||
      oldDelegate.flat != flat ||
      oldDelegate.wick != wick;
}
