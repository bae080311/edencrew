import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../data/model/daily_price.dart';
import '../../data/model/price_tone.dart';

/// 캔들 · 거래량 바 · 축 라벨 · 기간 방향 영역 · 크로스헤어를 한 캔버스에 그린다.
/// 색은 전부 주입받는다 — `BuildContext` 없이 토큰에 닿을 수 없기 때문이다.
class CandlePainter extends CustomPainter {
  CandlePainter({
    required this.prices,
    required this.focusIndex,
    required this.progress,
    required this.up,
    required this.down,
    required this.flat,
    required this.wick,
    required this.areaUp,
    required this.areaDown,
    required this.axisLabel,
    required this.volumeBar,
  });

  final List<DailyPrice> prices;
  final int? focusIndex;

  /// 0 → 1 로 가며 왼쪽(과거)부터 차례로 드러난다.
  final double progress;
  final Color up;
  final Color down;
  final Color flat;
  final Color wick;
  final Color areaUp;
  final Color areaDown;
  final Color axisLabel;
  final Color volumeBar;

  /// 캔들 사이 간격은 시안 값(1.2). 심지 굵기는 시안이 0.3 이지만 1년치 245개를
  /// 그리면 사라져서 최소 굵기를 따로 잡았다.
  static const double _gap = 1.2;
  static const double _minWidth = 0.8;

  /// 맨 위 · 맨 아래 캔들의 심지가 잘리지 않을 만큼만 띄운다.
  static const double _inset = 4;

  /// 세로 배분 — 가격 : 거래량 : 날짜 라벨. 합이 1 이다.
  static const double _priceRatio = 0.66;
  static const double _volumeRatio = 0.2;

  static const double _labelSize = 10;

  /// 동시에 차오르는 봉 개수. 1 이면 딱딱 끊기고, 너무 크면 전체가 한꺼번에 뜬다.
  static const double _wave = 8;

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.isEmpty) return;

    final double priceBottom = size.height * _priceRatio;
    final double volumeTop = priceBottom + size.height * 0.04;
    final double volumeBottom = volumeTop + size.height * _volumeRatio;

    int lowest = prices.first.low;
    int highest = prices.first.high;
    int peakVolume = prices.first.volume;
    for (final DailyPrice price in prices) {
      lowest = math.min(lowest, price.low);
      highest = math.max(highest, price.high);
      peakVolume = math.max(peakVolume, price.volume);
    }

    final double span = (highest - lowest).toDouble();
    final double usable = math.max(priceBottom - _inset * 2, 1);
    // 구간 전체가 같은 값이면 나눌 것이 없다. 가운데 한 줄로 그린다.
    double y(int value) => span == 0
        ? priceBottom / 2
        : _inset + usable * (highest - value) / span;

    final double slot = size.width / prices.length;
    final double bodyWidth = math.max(slot - _gap, _minWidth);

    // 오래된 순으로 세워 둔다 — 그리기와 좌표 계산이 같은 순서를 쓴다.
    final List<DailyPrice> oldestFirst = prices.reversed.toList(
      growable: false,
    );

    // 등장은 왼쪽(과거)부터 물결처럼 번져 간다. 잘라서 드러내기만 하면 티가 안 나서
    // 물결이 지나간 자리의 봉이 제자리에서 차오르게 한다.
    // 축 라벨과 크로스헤어는 전체 기준이라 숫자가 흔들리지 않는다.
    double growOf(int index) {
      if (progress >= 1) return 1;
      final double head = progress * (oldestFirst.length + _wave);
      return ((head - index) / _wave).clamp(0.0, 1.0);
    }

    _paintArea(canvas, size, oldestFirst, slot, y, priceBottom, growOf);
    _paintVolume(
      canvas,
      oldestFirst,
      slot,
      bodyWidth,
      peakVolume,
      volumeTop,
      volumeBottom,
      growOf,
    );
    _paintCandles(
      canvas,
      oldestFirst,
      slot,
      bodyWidth,
      y,
      priceBottom,
      growOf,
    );
    _paintAxisLabels(canvas, size, oldestFirst, highest, lowest, volumeBottom);
    _paintFocus(canvas, size, oldestFirst, slot, y, volumeBottom);
  }

  /// 기간 전체가 오른 구간인지 내린 구간인지에 따라 종가 추이 아래를 옅게 채운다.
  /// 캔들 뒤에 깔리므로 캔들 색을 가리지 않는다.
  void _paintArea(
    Canvas canvas,
    Size size,
    List<DailyPrice> oldestFirst,
    double slot,
    double Function(int) y,
    double priceBottom,
    double Function(int) growOf,
  ) {
    final int first = oldestFirst.first.close;
    final int last = oldestFirst.last.close;
    if (last == first) return;

    // 드러난 데까지만 채운다 — 물결 앞머리에서 끊긴다.
    final Path path = Path()..moveTo(0, priceBottom);
    double right = 0;
    for (int i = 0; i < oldestFirst.length; i++) {
      if (growOf(i) <= 0) break;
      right = slot * (i + 0.5);
      path.lineTo(right, y(oldestFirst[i].close));
    }
    if (right == 0) return;
    path
      ..lineTo(right, priceBottom)
      ..close();

    canvas.drawPath(path, Paint()..color = last > first ? areaUp : areaDown);
  }

  void _paintVolume(
    Canvas canvas,
    List<DailyPrice> oldestFirst,
    double slot,
    double bodyWidth,
    int peakVolume,
    double top,
    double bottom,
    double Function(int) growOf,
  ) {
    if (peakVolume <= 0) return;

    final Paint paint = Paint()..color = volumeBar;
    final double height = bottom - top;
    for (int i = 0; i < oldestFirst.length; i++) {
      final double grow = growOf(i);
      if (grow <= 0) break;
      // 거래량 바는 바닥에서 자란다.
      final double barHeight =
          height * oldestFirst[i].volume / peakVolume * grow;
      final double centerX = slot * (i + 0.5);
      canvas.drawRect(
        Rect.fromLTRB(
          centerX - bodyWidth / 2,
          // 거래량 0 인 날도 바닥에 한 줄은 남긴다.
          bottom - math.max(barHeight, _minWidth),
          centerX + bodyWidth / 2,
          bottom,
        ),
        paint,
      );
    }
  }

  void _paintCandles(
    Canvas canvas,
    List<DailyPrice> oldestFirst,
    double slot,
    double bodyWidth,
    double Function(int) y,
    double priceBottom,
    double Function(int) growOf,
  ) {
    final double wickWidth = math.max(_minWidth, bodyWidth * 0.2);
    final Paint wickPaint = Paint()
      ..color = wick
      ..strokeWidth = wickWidth;

    for (int i = 0; i < oldestFirst.length; i++) {
      final double grow = growOf(i);
      if (grow <= 0) break;

      final DailyPrice price = oldestFirst[i];
      final double centerX = slot * (i + 0.5);

      // 바닥에서 제자리까지 올라온다. 색은 처음부터 제 색이라 깜박이지 않는다.
      double from(double target) => priceBottom + (target - priceBottom) * grow;

      canvas.drawLine(
        Offset(centerX, from(y(price.high))),
        Offset(centerX, from(y(price.low))),
        wickPaint,
      );

      final double top = from(y(math.max(price.open, price.close)));
      final double bottom = from(y(math.min(price.open, price.close)));
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

  /// 가격 축은 오른쪽 위·아래에 최고가·최저가, 날짜 축은 아래 양끝에 첫·마지막 거래일.
  /// 눈금을 촘촘히 넣으면 1년치에서 글자가 겹친다.
  void _paintAxisLabels(
    Canvas canvas,
    Size size,
    List<DailyPrice> oldestFirst,
    int highest,
    int lowest,
    double volumeBottom,
  ) {
    _label(canvas, thousands(highest), size.width, 0, alignRight: true);
    _label(
      canvas,
      thousands(lowest),
      size.width,
      size.height * _priceRatio - _labelSize * 1.4,
      alignRight: true,
    );

    final double dateTop = volumeBottom + 4;
    _label(canvas, monthDay(oldestFirst.first.date), 0, dateTop);
    _label(
      canvas,
      monthDay(oldestFirst.last.date),
      size.width,
      dateTop,
      alignRight: true,
    );
  }

  /// 짚은 거래일에 세로선을 긋고 종가 · 거래량을 띄운다.
  void _paintFocus(
    Canvas canvas,
    Size size,
    List<DailyPrice> oldestFirst,
    double slot,
    double Function(int) y,
    double volumeBottom,
  ) {
    final int? index = focusIndex;
    if (index == null || index >= oldestFirst.length) return;

    final DailyPrice price = oldestFirst[index];
    final double centerX = slot * (index + 0.5);

    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, volumeBottom),
      Paint()
        ..color = axisLabel
        ..strokeWidth = 1,
    );

    final double closeY = y(price.close);
    canvas.drawCircle(
      Offset(centerX, closeY),
      2.5,
      Paint()..color = _colorOf(price.candleTone),
    );

    // 오른쪽 끝에서는 글자가 잘리므로 왼쪽으로 붙인다.
    final bool toLeft = centerX > size.width * 0.6;
    _label(
      canvas,
      '${monthDay(price.date)}  ${thousands(price.close)}',
      toLeft ? centerX - 6 : centerX + 6,
      0,
      alignRight: toLeft,
    );
  }

  void _label(
    Canvas canvas,
    String text,
    double x,
    double y, {
    bool alignRight = false,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: axisLabel, fontSize: _labelSize),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(alignRight ? x - painter.width : x, y));
  }

  Color _colorOf(PriceTone tone) => switch (tone) {
    PriceTone.up => up,
    PriceTone.down => down,
    PriceTone.flat => flat,
  };

  @override
  bool shouldRepaint(CandlePainter oldDelegate) =>
      oldDelegate.prices != prices ||
      oldDelegate.focusIndex != focusIndex ||
      oldDelegate.progress != progress ||
      oldDelegate.up != up ||
      oldDelegate.down != down ||
      oldDelegate.flat != flat ||
      oldDelegate.wick != wick ||
      oldDelegate.areaUp != areaUp ||
      oldDelegate.areaDown != areaDown ||
      oldDelegate.axisLabel != axisLabel ||
      oldDelegate.volumeBar != volumeBar;
}
