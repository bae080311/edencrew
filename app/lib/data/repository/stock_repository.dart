import '../model/chart_period.dart';
import '../model/daily_price.dart';
import '../model/quote.dart';
import '../model/stock.dart';

/// 화면이 바라보는 데이터 창구. 실제 구현과 목업 구현을 바꿔 끼운다.
///
/// 페이지 캐시 · 메타 캐시는 구현 내부에 숨긴다 — ViewModel 은 캐시를 모르고
/// "이 기간 데이터를 달라"고만 요청한다.
abstract class StockRepository {
  /// 국내 · 6자리 종목만 통과시킨 검색 결과.
  Future<List<Stock>> searchStocks(String query);

  /// 여러 종목의 시세를 **한 번의 요청으로** 가져온다.
  ///
  /// 값을 받지 못한 종목은 결과에서 빠진다. 화면은 그 행을 스켈레톤으로 남긴다.
  Future<Map<String, Quote>> fetchQuotes(List<String> symbols);

  Future<Stock> fetchStockMeta(String symbol);

  /// 기간에 필요한 만큼만 페이지를 받고 이미 받은 페이지는 재사용한다.
  /// 최신 거래일이 먼저 온다.
  Future<List<DailyPrice>> fetchDailyPrices(String symbol, ChartPeriod period);
}
