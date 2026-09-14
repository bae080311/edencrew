import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/model/daily_price.dart';
import '../../theme/theme.dart';
import 'candle_painter.dart';
import 'chart_axis_ui.dart';

/// 일별 시세 차트. 캔들 · 거래량 바 · 축 라벨 · 기간 방향 영역 · 크로스헤어를
/// 한 캔버스에 그린다. 짚은 자리의 날짜 · 종가도 캔버스 안에 띄운다.
class CandleChart extends StatefulWidget {
  const CandleChart({required this.prices, required this.axis, super.key});

  /// 최신 거래일이 먼저 온다. 왼쪽이 과거가 되도록 뒤에서부터 그린다.
  final List<DailyPrice> prices;

  /// 축 · 크로스헤어 문자열. 포맷은 ViewModel 이 끝낸다.
  final ChartAxisUi axis;

  /// 시안 `Chart` 프레임 높이. 이 화면 밖에서 쓰지 않아 토큰으로 올리지 않았다.
  static const double _height = 200;

  @override
  State<CandleChart> createState() => _CandleChartState();
}

/// 등장 애니메이션 길이. 화면을 여는 흐름을 끊지 않을 만큼만 준다 —
/// 길면 값을 확인하러 온 사람을 기다리게 한다. 이보다 짧으면 물결이 안 보이고
/// 그냥 툭 뜨는 것과 같아진다.
const Duration _reveal = Duration(milliseconds: 410);

class _CandleChartState extends State<CandleChart>
    with SingleTickerProviderStateMixin {
  int? _focusIndex;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _reveal,
  )..forward();

  /// 앞부분이 빠르게 지나가고 끝에서 잦아든다. 선형이면 끝까지 같은 속도라 늘어진다.
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void didUpdateWidget(CandleChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 기간을 바꿔 봉이 갈리면 다시 왼쪽부터 그린다.
    if (!identical(oldWidget.prices, widget.prices)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return SizedBox(
      height: CandleChart._height,
      width: double.infinity,
      child: GestureDetector(
        onHorizontalDragStart: (DragStartDetails d) =>
            _focus(d.localPosition.dx),
        onHorizontalDragUpdate: (DragUpdateDetails d) =>
            _focus(d.localPosition.dx),
        onHorizontalDragEnd: (_) => _clear(),
        onHorizontalDragCancel: _clear,
        onTapDown: (TapDownDetails d) => _focus(d.localPosition.dx),
        onTapUp: (_) => _clear(),
        onTapCancel: _clear,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? _) => CustomPaint(
            painter: CandlePainter(
              prices: widget.prices,
              axis: widget.axis,
              focusIndex: _focusIndex,
              progress: _curve.value,
              up: colors.chartLineUp,
              down: colors.chartLineDown,
              flat: colors.chartLineFlat,
              wick: colors.chartBaseline,
              areaUp: colors.chartAreaUp,
              areaDown: colors.chartAreaDown,
              axisLabel: colors.chartAxisLabel,
              volumeBar: colors.chartVolumeBar,
              labelStyle: AppTypography.caption.copyWith(
                color: colors.chartAxisLabel,
              ),
              textScaler: MediaQuery.textScalerOf(context),
            ),
          ),
        ),
      ),
    );
  }

  /// 가로 위치를 거래일 인덱스로 바꾼다. 그리는 순서와 같게 뒤에서부터 센다.
  void _focus(double dx) {
    final int count = widget.prices.length;
    if (count == 0) return;

    final double width = context.size?.width ?? 0;
    if (width <= 0) return;

    final int slot = (dx / (width / count)).floor().clamp(0, count - 1);
    if (slot == _focusIndex) return;

    setState(() => _focusIndex = slot);
    // 봉이 바뀔 때마다 한 번. 손가락이 어디를 짚었는지 화면을 안 봐도 안다.
    HapticFeedback.selectionClick();
  }

  void _clear() {
    if (_focusIndex == null) return;
    setState(() => _focusIndex = null);
  }
}
