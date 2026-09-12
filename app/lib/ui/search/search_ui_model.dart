/// 검색 결과의 한 행.
class SearchRowUi {
  const SearchRowUi({
    required this.symbol,
    required this.name,
    required this.marketLabel,
    required this.isFavorite,
    this.highlightStart = -1,
    this.highlightEnd = -1,
  });

  final String symbol;
  final String name;

  /// `005930 · 코스피`
  final String marketLabel;
  final bool isFavorite;

  /// 종목명에서 검색어와 맞는 구간. 맞는 곳이 없으면 둘 다 -1.
  /// 구간 계산은 ViewModel 몫이고 View 는 잘라 칠하기만 한다.
  final int highlightStart;
  final int highlightEnd;

  bool get hasHighlight => highlightStart >= 0;
}
