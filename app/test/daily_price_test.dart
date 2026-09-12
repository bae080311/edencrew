import 'package:edencrew_assignment_starter/data/model/daily_price.dart';
import 'package:edencrew_assignment_starter/data/model/price_tone.dart';
import 'package:flutter_test/flutter_test.dart';

DailyPrice priceOf({
  required int diff,
  required int open,
  required int close,
}) => DailyPrice(
  date: '20260911',
  close: close,
  diff: diff,
  open: open,
  high: close > open ? close : open,
  low: close < open ? close : open,
  volume: 100,
);

void main() {
  group('tone — 전일비', () {
    test('표의 등락은 전일비를 따른다', () {
      expect(priceOf(diff: 1200, open: 100, close: 100).tone, PriceTone.up);
      expect(priceOf(diff: -400, open: 100, close: 100).tone, PriceTone.down);
      expect(priceOf(diff: 0, open: 100, close: 100).tone, PriceTone.flat);
    });
  });

  group('candleTone — 몸통 방향', () {
    test('시가보다 종가가 높으면 양봉', () {
      expect(
        priceOf(diff: 0, open: 100, close: 110).candleTone,
        PriceTone.up,
      );
    });

    test('갭 상승 뒤 밀린 날은 전일비와 몸통이 갈린다', () {
      // 전일 종가 100 · 시가 110 · 종가 105 — 전일비는 +5 지만 몸통은 내렸다.
      final DailyPrice price = priceOf(diff: 5, open: 110, close: 105);
      expect(price.tone, PriceTone.up);
      expect(price.candleTone, PriceTone.down);
    });

    test('시가 = 종가는 보합', () {
      expect(
        priceOf(diff: -400, open: 100, close: 100).candleTone,
        PriceTone.flat,
      );
    });
  });
}
