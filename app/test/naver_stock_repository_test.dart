import 'dart:io';

import 'package:cp949_codec/cp949_codec.dart';
import 'package:edencrew_assignment_starter/data/model/chart_period.dart';
import 'package:edencrew_assignment_starter/data/repository/naver_stock_repository.dart';
import 'package:edencrew_assignment_starter/data/source/naver_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// 요청한 일별 시세 페이지 번호를 순서대로 기록한다.
class RecordingSiseDay {
  RecordingSiseDay({this.lastPage});

  final int? lastPage;
  final List<int> requestedPages = <int>[];

  http.Client get client => MockClient((http.Request request) async {
    final int page = int.parse(request.url.queryParameters['page']!);
    requestedPages.add(page);

    // 저장해 둔 페이지는 둘뿐이라 그 밖은 1페이지로 응답한다 — 이 테스트가 보는 건
    // 내용이 아니라 요청 횟수다.
    final File file = File(
      'assets/mock/sise_day_005930_p${page <= 2 ? page : 1}.html',
    );
    List<int> bytes = file.readAsBytesSync();
    if (lastPage != null) {
      // `맨뒤` 링크를 고쳐 마지막 페이지를 좁힌다.
      bytes = cp949.encode(
        cp949.decode(bytes).replaceAll('page=756', 'page=$lastPage'),
      );
    }
    return http.Response.bytes(bytes, 200);
  });
}

void main() {
  test('1개월은 2페이지만 요청한다', () async {
    final recorder = RecordingSiseDay();
    final repository = NaverStockRepository(
      api: NaverApi(client: recorder.client),
    );

    await repository.fetchDailyPrices('005930', ChartPeriod.oneMonth);

    expect(recorder.requestedPages..sort(), <int>[1, 2]);
  });

  test('1개월 → 3개월 전환 때 이미 받은 1 · 2 페이지를 다시 받지 않는다', () async {
    final recorder = RecordingSiseDay();
    final repository = NaverStockRepository(
      api: NaverApi(client: recorder.client),
    );

    await repository.fetchDailyPrices('005930', ChartPeriod.oneMonth);
    recorder.requestedPages.clear();

    await repository.fetchDailyPrices('005930', ChartPeriod.threeMonths);

    expect(recorder.requestedPages..sort(), <int>[3, 4, 5, 6]);
  });

  test('같은 기간을 다시 요청하면 아예 받지 않는다', () async {
    final recorder = RecordingSiseDay();
    final repository = NaverStockRepository(
      api: NaverApi(client: recorder.client),
    );

    await repository.fetchDailyPrices('005930', ChartPeriod.oneMonth);
    recorder.requestedPages.clear();

    await repository.fetchDailyPrices('005930', ChartPeriod.oneMonth);

    expect(recorder.requestedPages, isEmpty);
  });

  test('lastPage 를 넘는 페이지는 요청하지 않는다', () async {
    final recorder = RecordingSiseDay(lastPage: 3);
    final repository = NaverStockRepository(
      api: NaverApi(client: recorder.client),
    );

    // 1년은 25페이지를 원하지만 마지막 페이지가 3이다.
    await repository.fetchDailyPrices('005930', ChartPeriod.oneYear);

    expect(recorder.requestedPages..sort(), <int>[1, 2, 3]);
  });

  test('기간이 요구하는 거래일 수를 넘겨 주지 않는다', () async {
    final recorder = RecordingSiseDay();
    final repository = NaverStockRepository(
      api: NaverApi(client: recorder.client),
    );

    final prices = await repository.fetchDailyPrices(
      '005930',
      ChartPeriod.oneMonth,
    );

    expect(prices.length, ChartPeriod.oneMonth.tradingDays);
    expect(prices.first.date, '20260911');
  });

  test('종목이 다르면 캐시를 공유하지 않는다', () async {
    final recorder = RecordingSiseDay();
    final repository = NaverStockRepository(
      api: NaverApi(client: recorder.client),
    );

    await repository.fetchDailyPrices('005930', ChartPeriod.oneMonth);
    recorder.requestedPages.clear();

    await repository.fetchDailyPrices('000660', ChartPeriod.oneMonth);

    expect(recorder.requestedPages..sort(), <int>[1, 2]);
  });
}
