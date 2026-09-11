import '../model/daily_price.dart';

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

/// 일별 시세 한 페이지. `lastPage` 를 넘겨 초과 요청을 막는다.
class SiseDayPageDto {
  const SiseDayPageDto({required this.items, required this.lastPage});

  final List<DailyPriceDto> items;
  final int lastPage;
}
