/// 종목의 기본 정보. 검색 · 관심 · 상세 세 화면이 함께 쓴다.
class Stock {
  const Stock({
    required this.symbol,
    required this.name,
    required this.exchangeName,
  });

  /// 6자리 종목코드.
  final String symbol;
  final String name;

  /// 거래소명. 화면의 `005930 · 코스피` 에서 뒷부분이다.
  final String exchangeName;

  /// 앱 내부 식별자. 자동완성 응답에 지수 · 해외 종목 · IPO 가 섞여 오므로
  /// 국내 6자리만 통과시켜 내부를 단일 규칙으로 유지한다.
  String get canonicalId => 'domestic:$symbol';

  Stock copyWith({String? name, String? exchangeName}) => Stock(
    symbol: symbol,
    name: name ?? this.name,
    exchangeName: exchangeName ?? this.exchangeName,
  );
}
