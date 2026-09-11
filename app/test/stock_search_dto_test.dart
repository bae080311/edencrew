import 'dart:convert';
import 'dart:io';

import 'package:edencrew_assignment_starter/data/dto/stock_search_dto.dart';
import 'package:flutter_test/flutter_test.dart';

StockSearchDto dtoOf({
  required String code,
  String name = '이름',
  String? nationCode = 'KOR',
  String category = 'stock',
  String typeName = '코스피',
}) => StockSearchDto(
  code: code,
  name: name,
  typeName: typeName,
  nationCode: nationCode,
  category: category,
);

void main() {
  group('국내 종목 걸러내기 — 응답에 지수 · 해외 · IPO 가 섞여 온다', () {
    test('국내 6자리 종목만 통과한다', () {
      expect(dtoOf(code: '005930').isDomesticStock, isTrue);
    });

    test('지수는 막는다 — nationCode 가 없고 코드가 숫자가 아니다', () {
      expect(
        dtoOf(
          code: 'KOSPI',
          nationCode: null,
          category: 'index',
          typeName: '국내지수',
        ).isDomesticStock,
        isFalse,
      );
    });

    test('해외 종목은 막는다', () {
      expect(dtoOf(code: 'AAPL', nationCode: 'USA').isDomesticStock, isFalse);
      expect(dtoOf(code: '164A', nationCode: 'JPN').isDomesticStock, isFalse);
    });

    test('6자리가 아닌 코드는 막는다', () {
      expect(dtoOf(code: '2788').isDomesticStock, isFalse);
      expect(dtoOf(code: '0059300').isDomesticStock, isFalse);
    });

    test('종목이 아닌 category 는 막는다', () {
      expect(dtoOf(code: '123456', category: 'ipo').isDomesticStock, isFalse);
    });
  });

  group('저장해 둔 실제 응답', () {
    test('삼성 검색 결과 10건이 모두 국내 종목이다', () {
      final response =
          jsonDecode(
                utf8.decode(
                  File('assets/mock/ac_samsung.json').readAsBytesSync(),
                ),
              )
              as Map<String, dynamic>;

      final items = StockSearchDto.listFromResponse(response);

      expect(items.length, 10);
      expect(items.every((dto) => dto.isDomesticStock), isTrue);
      expect(items.first.name, '삼성전자');
      expect(items.first.typeName, '코스피');
    });

    test('껍데기가 어긋나면 빈 목록을 준다', () {
      expect(StockSearchDto.listFromResponse(<String, dynamic>{}), isEmpty);
    });
  });
}
