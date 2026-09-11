/// 등락 방향. 색은 View 가 `context.colors` 로 매핑한다.
///
/// UI 모델에 `Color` 를 담을 수 없어(토큰 접근에 `BuildContext` 가 필요하다) 의미만 넘긴다.
enum PriceTone {
  up,
  down,
  flat;

  static PriceTone of(num diff) {
    if (diff > 0) return PriceTone.up;
    if (diff < 0) return PriceTone.down;
    return PriceTone.flat;
  }
}
