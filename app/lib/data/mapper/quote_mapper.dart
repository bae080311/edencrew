import '../dto/realtime_quote_dto.dart';
import '../model/quote.dart';

/// 실시간 시세 응답 → 앱 모델.
extension RealtimeQuoteDtoMapper on RealtimeQuoteDto {
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
}
