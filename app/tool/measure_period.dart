// 기간별 조회가 어디서 시간을 쓰는지 잰다. 네트워크와 파싱을 나눠 본다.
//
//   dart run tool/measure_period.dart
import 'dart:io';

import 'package:edencrew_assignment_starter/data/model/chart_period.dart';
import 'package:edencrew_assignment_starter/data/model/daily_price.dart';
import 'package:edencrew_assignment_starter/data/repository/naver_stock_repository.dart';
import 'package:edencrew_assignment_starter/data/source/naver_api.dart';
import 'package:edencrew_assignment_starter/data/source/sise_day_parser.dart';

Future<void> main() async {
  final NaverApi api = NaverApi();

  stdout.writeln('— 페이지 1장: 네트워크와 파싱을 나눠 잰다');
  final Stopwatch one = Stopwatch()..start();
  final List<int> bytes = await api.fetchSiseDayPage('005930', 1);
  final int network = one.elapsedMilliseconds;

  one.reset();
  for (int i = 0; i < 10; i++) {
    SiseDayParser().parse(bytes, requestedPage: 1);
  }
  final double parse = one.elapsedMicroseconds / 10 / 1000;
  stdout.writeln('  네트워크 ${network}ms · 파싱 ${parse.toStringAsFixed(1)}ms/장');

  stdout.writeln('\n— 기간별 전체 (캐시 없는 상태에서 순서대로)');
  for (final ChartPeriod period in ChartPeriod.values) {
    // 기간마다 새 repository 를 써서 캐시 효과를 빼고 잰다.
    final repository = NaverStockRepository(api: api);
    final Stopwatch watch = Stopwatch()..start();
    final List<DailyPrice> prices = await repository.fetchDailyPrices(
      '005930',
      period,
    );
    stdout.writeln(
      '  ${period.name.padRight(12)} '
      '${period.pageCount.toString().padLeft(2)}장 '
      '${prices.length.toString().padLeft(3)}일 '
      '${watch.elapsedMilliseconds}ms',
    );
  }

  api.close();
}
