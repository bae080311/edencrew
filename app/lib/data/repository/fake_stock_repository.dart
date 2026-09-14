import 'dart:convert';

import 'package:cp949_codec/cp949_codec.dart';

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
import '../source/sise_day_parser.dart';
import 'stock_repository.dart';

/// 저장해 둔 응답으로 도는 개발용 구현. `--dart-define=USE_FAKE=true` 로 켠다.
///
/// **실제 구현과 같은 DTO · 파서를 쓴다** — 목업용 파싱을 따로 두면 목업에서만
/// 동작하는 화면이 된다.
class FakeStockRepository implements StockRepository {
  const FakeStockRepository({
    required this.loadAsset,
    SiseDayParser parser = const SiseDayParser(),
  }) : _parser = parser;

  /// `data` 는 `package:flutter/*` 를 import 하지 않으므로 asset 접근을 주입받는다.
  /// 앱은 `rootBundle`, 테스트는 `File` 을 넘긴다. 저장한 응답이 EUC-KR 이라
  /// 문자열이 아닌 **바이트**로 받아야 한다.
  final Future<List<int>> Function(String path) loadAsset;
  final SiseDayParser _parser;

  static const String _dir = 'assets/mock';

  @override
  Future<List<Stock>> searchStocks(String query) async {
    final String keyword = query.trim().toLowerCase();
    if (keyword.isEmpty) return const <Stock>[];

    final response = await _loadJson('$_dir/ac_samsung.json', utf8);
    // 저장해 둔 응답은 하나뿐이라 한 번 더 걸러 검색처럼 보이게 한다. 덕분에
    // `결과 없음` 상태도 목업으로 확인할 수 있다. 화면이 `종목명 또는 종목코드` 로
    // 안내하므로 코드도 받고, 대소문자는 실제 자동완성처럼 가리지 않는다.
    return StockSearchDto.listFromResponse(response)
        .where(
          (dto) =>
              dto.isDomesticStock &&
              (dto.name.toLowerCase().contains(keyword) ||
                  dto.code.contains(keyword)),
        )
        .map((dto) => dto.toStock())
        .toList(growable: false);
  }

  @override
  Future<Map<String, Quote>> fetchQuotes(List<String> symbols) async {
    if (symbols.isEmpty) return const <String, Quote>{};

    final response = await _loadJson('$_dir/realtime_batch.json', cp949);
    final Map<String, Quote> stored = <String, Quote>{
      for (final RealtimeQuoteDto dto in RealtimeQuoteDto.listFromResponse(
        response,
      ))
        dto.cd: dto.toQuote(),
    };
    // 저장해 두지 않은 종목은 빠진다 — 실제와 같이 그 행은 스켈레톤으로 남는다.
    return <String, Quote>{
      for (final String symbol in symbols)
        if (stored.containsKey(symbol)) symbol: stored[symbol]!,
    };
  }

  @override
  Future<Stock> fetchStockMeta(String symbol) async {
    try {
      final response = await _loadJson('$_dir/meta_$symbol.json', utf8);
      return StockMetaDto.fromJson(response).toStock();
    } on Object {
      // 메타를 저장해 두지 않은 종목은 검색 응답에서 이름과 시장을 찾는다.
      final response = await _loadJson('$_dir/ac_samsung.json', utf8);
      return StockSearchDto.listFromResponse(response)
          .firstWhere(
            (dto) => dto.code == symbol,
            orElse: () => throw Exception('목업에 $symbol 종목이 없다'),
          )
          .toStock();
    }
  }

  @override
  Future<List<DailyPrice>> fetchDailyPrices(
    String symbol,
    ChartPeriod period,
  ) async {
    final items = <DailyPrice>[];
    for (int page = 1; page <= period.pageCount; page++) {
      final List<int> bytes;
      try {
        bytes = await loadAsset('$_dir/sise_day_${symbol}_p$page.html');
      } on Object {
        break; // 저장해 둔 페이지까지만 준다
      }
      final SiseDayPageDto parsed = _parser.parse(bytes, requestedPage: page);
      items.addAll(parsed.items.map((dto) => dto.toDailyPrice()));
      if (page >= parsed.lastPage) break;
    }
    return items.take(period.tradingDays).toList(growable: false);
  }

  Future<Map<String, dynamic>> _loadJson(String path, Encoding codec) async {
    final Object? decoded = jsonDecode(codec.decode(await loadAsset(path)));
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('$path 가 객체가 아니다');
    }
    return decoded;
  }
}
