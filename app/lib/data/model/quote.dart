import 'price_tone.dart';

/// 실시간 시세. 등락과 시가총액은 응답 값을 쓰지 않고 여기서 계산한다.
///
/// 응답의 `cv` · `cr` 에는 부호가 없고 방향이 별도 코드(`rf`)로만 오기 때문에,
/// 명세가 지시한 식(`nv - pcv`)으로 직접 구하는 편이 정확하다.
class Quote {
  const Quote({
    required this.symbol,
    required this.price,
    required this.previousClose,
    required this.open,
    required this.high,
    required this.low,
    required this.volume,
    required this.listedShares,
  });

  final String symbol;
  final int price;
  final int previousClose;
  final int open;
  final int high;
  final int low;
  final int volume;
  final int listedShares;

  int get diff => price - previousClose;

  /// 비율(`0.0409`)로 돌려준다. 퍼센트 표기는 `core/format.dart` 몫이다.
  double get rate => previousClose == 0 ? 0 : diff / previousClose;

  int get marketCap => price * listedShares;

  PriceTone get tone => PriceTone.of(diff);
}
