import '../model/stock.dart';

/// 종목 메타데이터 응답. 필드명은 Naver 원본을 유지한다.
class StockMetaDto {
  const StockMetaDto({
    required this.symbolCode,
    required this.stockName,
    required this.stockExchangeNameKor,
  });

  final String symbolCode;
  final String stockName;

  /// `코스피` · `코스닥`. 화면의 `005930 · 코스피` 뒷부분이다.
  final String stockExchangeNameKor;

  Stock toStock() => Stock(
    symbol: symbolCode,
    name: stockName,
    exchangeName: stockExchangeNameKor,
  );

  factory StockMetaDto.fromJson(Map<String, dynamic> json) => StockMetaDto(
    symbolCode: json['symbolCode'] as String,
    stockName: json['stockName'] as String,
    stockExchangeNameKor: json['stockExchangeNameKor'] as String? ?? '',
  );
}
