import 'package:edencrew_assignment_starter/data/model/daily_price.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:edencrew_assignment_starter/ui/detail/candle_chart.dart';
import 'package:edencrew_assignment_starter/ui/detail/candle_painter.dart';
import 'package:edencrew_assignment_starter/ui/detail/chart_axis_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

DailyPrice priceOf(String date, int close) => DailyPrice(
  date: date,
  close: close,
  diff: 0,
  open: close,
  high: close + 100,
  low: close - 100,
  volume: 1000,
);

List<DailyPrice> pricesOf(int count) => List<DailyPrice>.generate(
  count,
  (int i) => priceOf('2026091${i % 10}', 50000 + i * 10),
);

/// 축 문자열은 ViewModel 이 만든다. 테스트는 그린 결과만 보므로 값만 맞춰 둔다.
ChartAxisUi axisOf(List<DailyPrice> prices) => ChartAxisUi(
  high: prices.map((DailyPrice p) => p.high).reduce((a, b) => a > b ? a : b),
  low: prices.map((DailyPrice p) => p.low).reduce((a, b) => a < b ? a : b),
  highLabel: '최고',
  lowLabel: '최저',
  firstDateLabel: '09.01',
  lastDateLabel: '09.10',
  focusLabels: List<String>.filled(prices.length, '09.05  50,000'),
);

const Size _canvas = Size(300, 200);

/// painter 가 **실제로 그린 것**을 센다. `progress` 값만 보면 그리기에 쓰이지
/// 않아도 통과한다 — 한 번 그렇게 놓쳤다.
///
/// 캔버스 호출을 직접 세어 판정한다. `Picture.approximateBytesUsed` 는 이름 그대로
/// 근사치라 백엔드에 따라 0 이 나올 수 있어 비교 기준이 되지 못한다.
int drawCallsAt(double progress) {
  // 색은 토큰에서 가져온다 — 테스트에도 hex 리터럴을 쓰지 않는다.
  const AppColors colors = AppColors.dark();
  final List<DailyPrice> prices = pricesOf(40);
  final painter = CandlePainter(
    prices: prices,
    axis: axisOf(prices),
    focusIndex: null,
    progress: progress,
    up: colors.chartLineUp,
    down: colors.chartLineDown,
    flat: colors.chartLineFlat,
    wick: colors.chartBaseline,
    areaUp: colors.chartAreaUp,
    areaDown: colors.chartAreaDown,
    axisLabel: colors.chartAxisLabel,
    volumeBar: colors.chartVolumeBar,
    labelStyle: AppTypography.caption.copyWith(color: colors.chartAxisLabel),
    textScaler: TextScaler.noScaling,
  );

  final _CountingCanvas canvas = _CountingCanvas();
  painter.paint(canvas, _canvas);
  return canvas.calls;
}

/// 그리기 호출만 센다. 실제 렌더링은 필요 없다.
class _CountingCanvas implements Canvas {
  int calls = 0;

  @override
  void noSuchMethod(Invocation invocation) {
    const Set<Symbol> drawing = <Symbol>{
      #drawRect,
      #drawLine,
      #drawPath,
      #drawCircle,
    };
    if (drawing.contains(invocation.memberName)) calls++;
  }
}

Widget chartWith(List<DailyPrice> prices) => MaterialApp(
  theme: AppTheme.dark,
  home: Scaffold(
    body: CandleChart(prices: prices, axis: axisOf(prices)),
  ),
);

CandlePainter painterOf(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.descendant(
                of: find.byType(CandleChart),
                matching: find.byType(CustomPaint),
              ),
            )
            .painter!
        as CandlePainter;

void main() {
  test('progress 가 그리기에 실제로 쓰인다', () {
    final int start = drawCallsAt(0);
    final int half = drawCallsAt(0.5);
    final int full = drawCallsAt(1);

    expect(start, lessThan(half), reason: '시작에는 거의 아무것도 안 그려진다');
    expect(half, lessThan(full), reason: '절반에는 일부만 그려진다');
  });

  testWidgets('왼쪽부터 드러난다 — progress 가 0 에서 1 로 흐른다', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(chartWith(pricesOf(20)));

    expect(painterOf(tester).progress, 0);

    await tester.pump(const Duration(milliseconds: 80));
    final double mid = painterOf(tester).progress;
    expect(mid, greaterThan(0));
    expect(mid, lessThan(1), reason: '중간에는 일부만 드러나 있어야 한다');

    await tester.pumpAndSettle();
    expect(painterOf(tester).progress, 1);
  });

  testWidgets('기간을 바꾸면 다시 왼쪽부터 그린다', (WidgetTester tester) async {
    await tester.pumpWidget(chartWith(pricesOf(20)));
    await tester.pumpAndSettle();
    expect(painterOf(tester).progress, 1);

    await tester.pumpWidget(chartWith(pricesOf(60)));
    await tester.pump();

    expect(
      painterOf(tester).progress,
      lessThan(1),
      reason: '새 구간은 처음부터 그려져야 한다',
    );

    await tester.pumpAndSettle();
  });
}
