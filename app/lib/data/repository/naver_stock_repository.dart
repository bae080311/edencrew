import 'dart:math';

import '../dto/daily_price_dto.dart';
import '../dto/sise_day_page_dto.dart';
import '../mapper/daily_price_mapper.dart';
import '../mapper/quote_mapper.dart';
import '../mapper/stock_meta_mapper.dart';
import '../mapper/stock_search_mapper.dart';
import '../dto/realtime_quote_dto.dart';
import '../dto/stock_meta_dto.dart';
import '../dto/stock_search_dto.dart';
import '../model/chart_period.dart';
import '../model/daily_price.dart';
import '../model/quote.dart';
import '../model/stock.dart';
import '../source/naver_api.dart';
import '../source/sise_day_parser.dart';
import 'stock_repository.dart';

/// 실제 endpoint 를 조회하는 기본 구현.
///
/// 일별 시세 페이지와 종목 메타를 안에 캐시한다 — ViewModel 은 캐시를 모른다.
class NaverStockRepository implements StockRepository {
  NaverStockRepository({NaverApi? api, SiseDayParser parser = const SiseDayParser()})
    : _api = api ?? NaverApi(),
      _parser = parser;

  final NaverApi _api;
  final SiseDayParser _parser;

  /// 완료된 결과가 아니라 **진행 중인 요청**을 담는다. 결과만 캐시하면 아직
  /// 도착하지 않은 페이지를 없는 것으로 보고 같은 페이지를 또 받는다.
  final Map<String, Map<int, Future<List<DailyPriceDto>>>> _pageCache =
      <String, Map<int, Future<List<DailyPriceDto>>>>{};
  final Map<String, int> _lastPage = <String, int>{};
  final Map<String, Stock> _metaCache = <String, Stock>{};

  @override
  Future<List<Stock>> searchStocks(String query) async {
    if (query.trim().isEmpty) return const <Stock>[];

    final response = await _api.fetchSearch(query);
    return StockSearchDto.listFromResponse(response)
        .where((dto) => dto.isDomesticStock)
        .map((dto) => dto.toStock())
        .toList(growable: false);
  }

  @override
  Future<Map<String, Quote>> fetchQuotes(List<String> symbols) async {
    if (symbols.isEmpty) return const <String, Quote>{};

    final response = await _api.fetchRealtimeQuotes(symbols);
    return <String, Quote>{
      for (final RealtimeQuoteDto dto
          in RealtimeQuoteDto.listFromResponse(response))
        dto.cd: dto.toQuote(),
    };
  }

  @override
  Future<Stock> fetchStockMeta(String symbol) async {
    final Stock? cached = _metaCache[symbol];
    if (cached != null) return cached;

    final dto = StockMetaDto.fromJson(await _api.fetchStockMeta(symbol));
    return _metaCache[symbol] = dto.toStock();
  }

  @override
  Future<List<DailyPrice>> fetchDailyPrices(
    String symbol,
    ChartPeriod period,
  ) async {
    final Map<int, Future<List<DailyPriceDto>>> cache = _pageCache.putIfAbsent(
      symbol,
      () => <int, Future<List<DailyPriceDto>>>{},
    );

    // `lastPage` 를 모르는 상태에서 여러 페이지를 한꺼번에 요청하면 초과 요청이
    // 섞인다. 1페이지를 먼저 받아 마지막 페이지를 확정한 뒤 나머지를 병렬로 받는다.
    if (_lastPage[symbol] == null && !cache.containsKey(1)) {
      await _pageOf(symbol, 1, cache);
    }

    final int until = min(period.pageCount, _lastPage[symbol] ?? 1);
    final List<List<DailyPriceDto>> pages = await Future.wait(
      <Future<List<DailyPriceDto>>>[
        for (int page = 1; page <= until; page++) _pageOf(symbol, page, cache),
      ],
    );

    final items = <DailyPrice>[];
    for (final List<DailyPriceDto> page in pages) {
      items.addAll(page.map((dto) => dto.toDailyPrice()));
    }
    // 1페이지 = 10거래일이라 마지막 페이지에서 기간보다 며칠 더 온다.
    return items.take(period.tradingDays).toList(growable: false);
  }

  /// 같은 페이지를 동시에 요청하면 먼저 시작한 요청을 함께 기다린다.
  Future<List<DailyPriceDto>> _pageOf(
    String symbol,
    int page,
    Map<int, Future<List<DailyPriceDto>>> cache,
  ) {
    final Future<List<DailyPriceDto>>? inFlight = cache[page];
    if (inFlight != null) return inFlight;

    // 실패한 요청까지 남으면 다시 시도할 수 없어 캐시에서 걷어낸다.
    final Future<List<DailyPriceDto>> request = _loadPage(symbol, page)
        .onError<Object>((Object error, StackTrace stack) {
          cache.remove(page);
          throw error;
        });
    cache[page] = request;
    return request;
  }

  Future<List<DailyPriceDto>> _loadPage(String symbol, int page) async {
    final SiseDayPageDto parsed = _parser.parse(
      await _api.fetchSiseDayPage(symbol, page),
      requestedPage: page,
    );
    _lastPage[symbol] = parsed.lastPage;
    return parsed.items;
  }

}
