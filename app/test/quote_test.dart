import 'package:edencrew_assignment_starter/data/model/price_tone.dart';
import 'package:edencrew_assignment_starter/data/model/quote.dart';
import 'package:flutter_test/flutter_test.dart';

Quote quoteOf({
  required int price,
  required int previousClose,
  int listedShares = 1000000,
}) => Quote(
  symbol: '005930',
  price: price,
  previousClose: previousClose,
  open: price,
  high: price,
  low: price,
  volume: 0,
  listedShares: listedShares,
);

void main() {
  test('상승 — 등락액·등락률이 양수이고 tone 은 up', () {
    final quote = quoteOf(price: 269000, previousClose: 258000);

    expect(quote.diff, 11000);
    expect(quote.rate, closeTo(0.04264, 0.00001));
    expect(quote.tone, PriceTone.up);
  });

  test('하락 — 음수이고 tone 은 down', () {
    final quote = quoteOf(price: 180000, previousClose: 180400);

    expect(quote.diff, -400);
    expect(quote.rate, closeTo(-0.002217, 0.000001));
    expect(quote.tone, PriceTone.down);
  });

  test('보합 — 0 이고 tone 은 flat', () {
    final quote = quoteOf(price: 258000, previousClose: 258000);

    expect(quote.diff, 0);
    expect(quote.rate, 0);
    expect(quote.tone, PriceTone.flat);
  });

  test('전일 종가가 0 이면 등락률을 0 으로 둔다 — 0 으로 나누지 않는다', () {
    final quote = quoteOf(price: 258000, previousClose: 0);

    expect(quote.rate, 0);
    expect(quote.tone, PriceTone.up);
  });

  test('시가총액은 현재가 × 상장주식수', () {
    final quote = quoteOf(
      price: 258250,
      previousClose: 269000,
      listedShares: 5846278608,
    );

    expect(quote.marketCap, 258250 * 5846278608);
  });
}
