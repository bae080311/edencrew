import '../dto/daily_price_dto.dart';
import '../model/daily_price.dart';

/// 일별 시세 표의 한 행 → 앱 모델.
extension DailyPriceDtoMapper on DailyPriceDto {
  /// 날짜를 `yyyyMMdd` 로 정규화한다 — 앱 내부는 이 형식만 쓴다.
  DailyPrice toDailyPrice() => DailyPrice(
    date: localDate.replaceAll('.', ''),
    close: closePrice,
    diff: previousDayCompare,
    open: openPrice,
    high: highPrice,
    low: lowPrice,
    volume: accumulatedTradingVolume,
  );
}
