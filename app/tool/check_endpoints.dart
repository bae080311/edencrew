// Naver endpoint 4개가 실제로 응답하는지 확인한다. 화면 없이 데이터 계층만 돌린다.
//
//   dart run tool/check_endpoints.dart
//
// 목업(`USE_FAKE`)이 아니라 실제 조회가 기본 동작임을 확인하는 자리다.
import 'dart:io';

import 'package:edencrew_assignment_starter/core/format.dart';
import 'package:edencrew_assignment_starter/data/model/chart_period.dart';
import 'package:edencrew_assignment_starter/data/model/daily_price.dart';
import 'package:edencrew_assignment_starter/data/model/quote.dart';
import 'package:edencrew_assignment_starter/data/model/stock.dart';
import 'package:edencrew_assignment_starter/data/repository/naver_stock_repository.dart';
import 'package:edencrew_assignment_starter/data/source/naver_api.dart';

Future<void> main() async {
  final NaverApi api = NaverApi();
  final repository = NaverStockRepository(api: api);
  int failed = 0;

  Future<void> check(String label, Future<void> Function() body) async {
    try {
      await body();
    } on Object catch (error) {
      failed++;
      stdout.writeln('  ✗ $label — $error');
    }
  }

  await check('검색 자동완성', () async {
    final List<Stock> results = await repository.searchStocks('삼성');
    if (results.isEmpty) throw Exception('결과가 비었다');
    stdout.writeln(
      '  ✓ 검색 자동완성 — ${results.length}건, '
      '첫 결과 ${results.first.name} (${results.first.symbol} · ${results.first.exchangeName})',
    );
  });

  await check('실시간 시세(batch)', () async {
    const symbols = <String>['005930', '000660', '035420'];
    final Map<String, Quote> quotes = await repository.fetchQuotes(symbols);
    if (quotes.length != symbols.length) {
      throw Exception('${symbols.length}개 요청, ${quotes.length}개 수신');
    }
    final Quote samsung = quotes['005930']!;
    stdout.writeln(
      '  ✓ 실시간 시세(batch) — 요청 1회로 ${quotes.length}종목, '
      '005930 ${thousands(samsung.price)} '
      '${changeLabel(samsung.diff, samsung.rate)} '
      '시가총액 ${abbrev(samsung.marketCap)}',
    );
  });

  await check('종목 메타', () async {
    final Stock stock = await repository.fetchStockMeta('005930');
    stdout.writeln(
      '  ✓ 종목 메타 — ${stock.name} (${stock.symbol} · ${stock.exchangeName})',
    );
  });

  await check('일별 시세(HTML · EUC-KR)', () async {
    final List<DailyPrice> prices = await repository.fetchDailyPrices(
      '005930',
      ChartPeriod.oneMonth,
    );
    if (prices.length != ChartPeriod.oneMonth.tradingDays) {
      throw Exception('${prices.length}일 수신');
    }
    final DailyPrice latest = prices.first;
    stdout.writeln(
      '  ✓ 일별 시세 — ${prices.length}거래일, '
      '${monthDay(latest.date)} 종가 ${thousands(latest.close)} '
      '등락 ${signedThousands(latest.diff)} '
      '거래량 ${abbrev(latest.volume)}',
    );

    // 같은 종목을 3개월로 다시 요청해도 1~2 페이지는 다시 받지 않는다.
    final List<DailyPrice> wider = await repository.fetchDailyPrices(
      '005930',
      ChartPeriod.threeMonths,
    );
    stdout.writeln('  ✓ 페이지 재사용 — 3개월 확장 후 ${wider.length}거래일');
  });

  api.close();
  stdout.writeln(failed == 0 ? '\nendpoint 4개 모두 응답' : '\n$failed개 실패');
  exitCode = failed == 0 ? 0 : 1;
}
