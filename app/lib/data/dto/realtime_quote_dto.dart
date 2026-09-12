import '../model/quote.dart';

/// 실시간 시세 응답의 한 종목. 필드명은 Naver 원본을 유지한다.
///
/// 응답 본문이 EUC-KR 이라 디코딩을 거친 문자열을 `jsonDecode` 해서 넘겨야 한다.
class RealtimeQuoteDto {
  const RealtimeQuoteDto({
    required this.cd,
    required this.nm,
    required this.nv,
    required this.pcv,
    required this.ov,
    required this.hv,
    required this.lv,
    required this.aq,
    required this.countOfListedStock,
  });

  final String cd;
  final String nm;
  final int nv;
  final int pcv;
  final int ov;
  final int hv;
  final int lv;
  final int aq;
  final int countOfListedStock;

  factory RealtimeQuoteDto.fromJson(Map<String, dynamic> json) =>
      RealtimeQuoteDto(
        cd: json['cd'] as String,
        nm: json['nm'] as String,
        nv: _int(json, 'nv'),
        pcv: _int(json, 'pcv'),
        ov: _int(json, 'ov'),
        hv: _int(json, 'hv'),
        lv: _int(json, 'lv'),
        aq: _int(json, 'aq'),
        countOfListedStock: _int(json, 'countOfListedStock'),
      );

  /// 응답 껍데기(`result.areas[].datas`)에서 종목 항목만 꺼낸다.
  ///
  /// 항목 하나가 어긋나도 나머지는 살린다 — 관심 목록의 한 종목이 거래정지 등으로
  /// 값이 비어 오는 경우 목록 전체가 실패하는 대신 그 행만 스켈레톤으로 남는다.
  static List<RealtimeQuoteDto> listFromResponse(Map<String, dynamic> json) {
    final result = json['result'];
    if (result is! Map<String, dynamic>) return const <RealtimeQuoteDto>[];
    final areas = result['areas'];
    if (areas is! List) return const <RealtimeQuoteDto>[];

    final quotes = <RealtimeQuoteDto>[];
    for (final area in areas) {
      if (area is! Map<String, dynamic>) continue;
      final datas = area['datas'];
      if (datas is! List) continue;
      for (final item in datas) {
        if (item is! Map<String, dynamic>) continue;
        try {
          quotes.add(RealtimeQuoteDto.fromJson(item));
        } on Object {
          continue;
        }
      }
    }
    return quotes;
  }

  Quote toQuote() => Quote(
    symbol: cd,
    price: nv,
    previousClose: pcv,
    open: ov,
    high: hv,
    low: lv,
    volume: aq,
    listedShares: countOfListedStock,
  );

  /// `nv` 처럼 정수로 오는 값이 종목에 따라 실수로 내려올 때가 있다.
  static int _int(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw FormatException('$key 가 숫자가 아니다', value);
  }
}
