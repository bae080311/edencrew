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

  PriceTone get tone => PriceTone.of(diff);
}
