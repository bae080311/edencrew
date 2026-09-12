import '../dto/stock_search_dto.dart';
import '../model/stock.dart';

/// 검색 자동완성 응답 → 앱 모델.
///
/// 시장명을 `typeName` 에서 가져오므로 결과마다 메타를 따로 조회하지 않아도 된다.
extension StockSearchDtoMapper on StockSearchDto {
  Stock toStock() => Stock(symbol: code, name: name, exchangeName: typeName);
}
