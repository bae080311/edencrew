import '../../data/model/price_tone.dart';

/// 관심 목록 정렬 기준. 표시 문자열은 View 가 갖는다.
enum WatchlistSort { price, changeRate, name }

/// 관심 목록의 한 행. View 는 이 값을 배치만 한다.
class WatchlistRowUi {
  const WatchlistRowUi({
    required this.symbol,
    required this.name,
    required this.marketLabel,
    required this.tone,
    this.priceLabel,
    this.changeLabel,
  });

  final String symbol;
  final String name;

  /// `005930 · 코스피`
  final String marketLabel;
  final PriceTone tone;

  /// 아직 시세를 받지 못했으면 null.
  final String? priceLabel;
  final String? changeLabel;

  /// 별도 플래그를 두지 않고 시세 유무에서 파생시킨다.
  bool get isSkeleton => priceLabel == null;
}
