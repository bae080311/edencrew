import 'dart:io';

import 'package:edencrew_assignment_starter/data/model/chart_period.dart';
import 'package:edencrew_assignment_starter/data/repository/fake_stock_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const repository = FakeStockRepository(loadAsset: _loadFromDisk);

Future<List<int>> _loadFromDisk(String path) async =>
    File(path).readAsBytesSync();

void main() {
  group('검색', () {
    test('이름에 검색어가 든 종목만 준다', () async {
      final results = await repository.searchStocks('삼성전자');

      expect(results.map((s) => s.symbol), ['005930', '005935']);
      expect(results.first.name, '삼성전자');
      expect(results.first.exchangeName, '코스피');
    });

    test('맞는 종목이 없으면 빈 목록 — `결과 없음` 상태를 목업으로 확인할 수 있다', () async {
      expect(await repository.searchStocks('없는종목'), isEmpty);
    });

    test('빈 검색어는 조회하지 않는다', () async {
      expect(await repository.searchStocks('   '), isEmpty);
    });
  });

  group('시세', () {
    test('요청한 종목만 골라 준다', () async {
      final quotes = await repository.fetchQuotes(['005930', '000660']);

      expect(quotes.keys.toSet(), {'005930', '000660'});
      expect(quotes['005930']!.price, 258000);
      expect(quotes['005930']!.previousClose, 269000);
    });

    test('저장해 두지 않은 종목은 빠진다 — 그 행은 스켈레톤으로 남는다', () async {
      final quotes = await repository.fetchQuotes(['005930', '999999']);

      expect(quotes.keys, ['005930']);
    });

    test('빈 목록이면 조회하지 않는다', () async {
      expect(await repository.fetchQuotes(const []), isEmpty);
    });
  });

  group('메타', () {
    test('저장해 둔 메타를 읽는다', () async {
      final stock = await repository.fetchStockMeta('005930');

      expect(stock.name, '삼성전자');
      expect(stock.exchangeName, '코스피');
      expect(stock.canonicalId, 'domestic:005930');
    });

    test('메타가 없는 종목은 검색 응답에서 찾는다', () async {
      final stock = await repository.fetchStockMeta('009150');

      expect(stock.name, '삼성전기');
      expect(stock.exchangeName, '코스피');
    });

    test('어디에도 없으면 예외를 던진다', () {
      expect(repository.fetchStockMeta('999999'), throwsA(isA<Exception>()));
    });
  });

  group('일별 시세', () {
    test('실제 구현과 같은 파서를 거쳐 정규화된 날짜를 준다', () async {
      final prices = await repository.fetchDailyPrices(
        '005930',
        ChartPeriod.oneMonth,
      );

      expect(prices.length, 20);
      expect(prices.first.date, '20260911');
      expect(prices.first.close, 257500);
      expect(prices.first.diff, -11500);
    });

    test('저장해 둔 페이지까지만 준다', () async {
      final prices = await repository.fetchDailyPrices(
        '005930',
        ChartPeriod.oneYear,
      );

      expect(prices.length, 20);
    });
  });
}
