/// 검색 자동완성 응답의 한 항목. 필드명은 Naver 원본을 유지한다.
class StockSearchDto {
  const StockSearchDto({
    required this.code,
    required this.name,
    required this.typeName,
    required this.nationCode,
    required this.category,
  });

  final String code;
  final String name;

  /// `코스피` 처럼 화면의 `005930 · 코스피` 뒷부분에 쓰인다.
  /// 여기 값이 있어 검색 결과마다 메타를 따로 조회하지 않아도 된다.
  final String typeName;

  /// 국내는 `KOR`. 지수 · 시장지표에는 이 필드가 없다.
  final String? nationCode;

  /// `stock` · `index` · `ipo` 로 갈린다.
  final String category;

  static final RegExp _domesticSymbol = RegExp(r'^\d{6}$');

  /// 응답에는 지수 · 해외 종목 · IPO 가 섞여 온다.
  /// 국내 · 종목 · 6자리만 통과시켜 내부를 단일 규칙으로 유지한다.
  bool get isDomesticStock =>
      nationCode == 'KOR' &&
      category == 'stock' &&
      _domesticSymbol.hasMatch(code);

  factory StockSearchDto.fromJson(Map<String, dynamic> json) => StockSearchDto(
    code: json['code'] as String,
    name: json['name'] as String,
    typeName: json['typeName'] as String? ?? '',
    nationCode: json['nationCode'] as String?,
    category: json['category'] as String? ?? '',
  );

  /// 응답 껍데기(`items`)에서 항목을 꺼낸다.
  /// 항목 하나가 어긋나도 나머지 검색 결과는 살린다.
  static List<StockSearchDto> listFromResponse(Map<String, dynamic> json) {
    final items = json['items'];
    if (items is! List) return const <StockSearchDto>[];

    final results = <StockSearchDto>[];
    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;
      try {
        results.add(StockSearchDto.fromJson(item));
      } on Object {
        continue;
      }
    }
    return results;
  }
}
