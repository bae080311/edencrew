import '../dto/stock_meta_dto.dart';
import '../model/stock.dart';

/// 종목 메타데이터 응답 → 앱 모델.
extension StockMetaDtoMapper on StockMetaDto {
  Stock toStock() => Stock(
    symbol: symbolCode,
    name: stockName,
    exchangeName: stockExchangeNameKor,
  );
}
