import 'price_tone.dart';

/// 일별 시세 한 행. 상세 화면의 차트와 표가 함께 쓴다.
class DailyPrice {
  const DailyPrice({
    required this.date,
    required this.close,
    required this.diff,
    required this.open,
    required this.high,
    required this.low,
    required this.volume,
  });

  /// `yyyyMMdd` 로 정규화된 거래일.
  final String date;
  final int close;

  /// 전일비. 부호를 포함한다.
  final int diff;
  final int open;
  final int high;
  final int low;
  final int volume;

  /// 전일비 방향. 일별 시세 표의 `등락` 이 쓴다.
  PriceTone get tone => PriceTone.of(diff);

  /// 캔들 몸통 방향. 몸통을 시가~종가로 그리므로 색도 같은 기준이어야 한다.
  /// 전일비와 갈릴 수 있다 — 전일 종가 100 · 시가 110 · 종가 105 는
  /// 전일비로는 상승이지만 몸통은 내렸다.
  PriceTone get candleTone => PriceTone.of(close - open);
}
