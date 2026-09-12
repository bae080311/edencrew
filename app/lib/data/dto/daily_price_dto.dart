/// 일별 시세 HTML 표의 한 행. 값은 원본 형식을 유지한다.
class DailyPriceDto {
  const DailyPriceDto({
    required this.localDate,
    required this.closePrice,
    required this.previousDayCompare,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.accumulatedTradingVolume,
  });

  /// 표에 적힌 그대로의 `yyyy.MM.dd`. `yyyyMMdd` 정규화는 모델 변환에서 한다.
  final String localDate;
  final int closePrice;

  /// 전일비. 표는 절대값만 보여주고 방향을 아이콘 class 로 구분하므로,
  /// 파싱 단계에서 부호를 합쳐 둔다.
  final int previousDayCompare;
  final int openPrice;
  final int highPrice;
  final int lowPrice;
  final int accumulatedTradingVolume;
}
