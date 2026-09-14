import 'dart:convert';
import 'dart:io';

import 'package:cp949_codec/cp949_codec.dart';
import 'package:edencrew_assignment_starter/data/dto/daily_price_dto.dart';
import 'package:edencrew_assignment_starter/data/source/sise_day_parser.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> mockBytes(String name) => File('assets/mock/$name').readAsBytesSync();

const parser = SiseDayParser();

void main() {
  group('EUC-KR 디코딩', () {
    test('cp949 로 읽으면 한글이 온전하고, UTF-8 로는 깨진다', () {
      final bytes = mockBytes('sise_day_005930_p1.html');

      expect(cp949.decode(bytes), contains('일별'));
      expect(cp949.decode(bytes), contains('전일비'));
      expect(() => utf8.decode(bytes), throwsA(isA<FormatException>()));
    });
  });

  group('표 파싱', () {
    test('데이터 행만 읽는다 — 헤더 · 구분선 행은 건너뛴다', () {
      final page = parser.parse(
        mockBytes('sise_day_005930_p1.html'),
        requestedPage: 1,
      );

      expect(page.items.length, 10);
    });

    test('컬럼 순서는 종가 · 전일비 · 시가 · 고가 · 저가 · 거래량', () {
      final DailyPriceDto latest = parser
          .parse(mockBytes('sise_day_005930_p1.html'), requestedPage: 1)
          .items
          .first;

      expect(latest.localDate, '2026.09.11');
      expect(latest.closePrice, 257500);
      expect(latest.previousDayCompare, -11500);
      expect(latest.openPrice, 258000);
      expect(latest.highPrice, 261000);
      expect(latest.lowPrice, 257500);
      expect(latest.accumulatedTradingVolume, 6448323);
    });

    test('최신 거래일이 먼저 온다', () {
      final page = parser.parse(
        mockBytes('sise_day_005930_p1.html'),
        requestedPage: 1,
      );

      expect(page.items.first.localDate, '2026.09.11');
      expect(page.items.last.localDate, '2026.08.31');
    });
  });

  group('전일비 부호 — 표는 절대값만 보여준다', () {
    late List<DailyPriceDto> items;

    setUp(() {
      items = parser
          .parse(mockBytes('sise_day_005930_p1.html'), requestedPage: 1)
          .items;
    });

    DailyPriceDto on(String date) =>
        items.firstWhere((item) => item.localDate == date);

    test('하락은 음수', () {
      expect(on('2026.09.11').previousDayCompare, -11500);
      expect(on('2026.09.10').previousDayCompare, -500);
    });

    test('상승은 양수', () {
      expect(on('2026.09.07').previousDayCompare, 14500);
      expect(on('2026.09.04').previousDayCompare, 5500);
    });

    test('보합은 0', () {
      expect(on('2026.09.09').previousDayCompare, 0);
    });
  });

  group('lastPage', () {
    test('맨뒤 링크에서 마지막 페이지를 읽는다', () {
      final page = parser.parse(
        mockBytes('sise_day_005930_p1.html'),
        requestedPage: 1,
      );

      expect(page.lastPage, 756);
    });

    test('마지막 페이지에는 맨뒤 링크가 없다 — 네비 최댓값으로 보정한다', () {
      final page = parser.parse(
        mockBytes('sise_day_005930_last.html'),
        requestedPage: 756,
      );

      expect(page.lastPage, 756);
      expect(page.items.length, 8);
    });

    test('페이지 정보를 못 읽으면 요청한 페이지를 하한으로 쓴다', () {
      final page = parser.parse(
        cp949.encode('<html></html>'),
        requestedPage: 3,
      );

      expect(page.lastPage, 3);
      expect(page.items, isEmpty);
    });
  });

  group('페이지 이어받기', () {
    test('다음 페이지는 앞 페이지보다 오래된 거래일을 준다', () {
      final first = parser.parse(
        mockBytes('sise_day_005930_p1.html'),
        requestedPage: 1,
      );
      final second = parser.parse(
        mockBytes('sise_day_005930_p2.html'),
        requestedPage: 2,
      );

      expect(second.items.first.localDate, '2026.08.28');
      expect(
        second.items.first.localDate.compareTo(first.items.last.localDate),
        lessThan(0),
      );
    });
  });
}
