/// 차트가 그릴 축 · 크로스헤어 **문자열**과 세로 눈금 기준값.
///
/// painter 는 `CustomPainter` 라 `BuildContext` 도 ViewModel 도 모른다. 그렇다고
/// painter 안에서 포맷하면 표시 문자열을 만드는 곳이 ViewModel 과 위젯 둘로
/// 갈린다(`rules/architecture.md` — View 는 배치만 한다). 그래서 ViewModel 이
/// 만들어 통째로 넘긴다.
class ChartAxisUi {
  const ChartAxisUi({
    required this.high,
    required this.low,
    required this.highLabel,
    required this.lowLabel,
    required this.firstDateLabel,
    required this.lastDateLabel,
    required this.focusLabels,
  });

  /// 비어 있는 구간. 그릴 것이 없을 때 쓴다.
  static const ChartAxisUi empty = ChartAxisUi(
    high: 0,
    low: 0,
    highLabel: '',
    lowLabel: '',
    firstDateLabel: '',
    lastDateLabel: '',
    focusLabels: <String>[],
  );

  /// 세로 눈금 기준. 좌표 계산에 쓰이므로 숫자 그대로다.
  final int high;
  final int low;

  final String highLabel;
  final String lowLabel;

  /// 가로축 양끝. 가운데 눈금은 1년치에서 글자가 겹쳐 넣지 않는다.
  final String firstDateLabel;
  final String lastDateLabel;

  /// 짚은 거래일에 띄울 `09.11  179,700`. **오래된 순**이라 그리는 순서와 같다.
  final List<String> focusLabels;

  bool get isEmpty => focusLabels.isEmpty;
}
