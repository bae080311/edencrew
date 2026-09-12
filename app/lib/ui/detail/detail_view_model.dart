import 'package:flutter/foundation.dart';

import '../../core/format.dart' as fmt;
import '../../data/model/chart_period.dart';
import '../../data/model/daily_price.dart';
import '../../data/model/price_tone.dart';
import '../../data/model/quote.dart';
import '../../data/model/stock.dart';
import '../../data/repository/stock_repository.dart';
import '../../state/favorites_store.dart';
import '../common/load_state.dart';
import 'detail_ui_model.dart';

/// 종목상세 화면의 상태와 계산을 맡는다.
class DetailViewModel extends ChangeNotifier {
  DetailViewModel({
    required StockRepository repository,
    required FavoritesStore favorites,
    required this.symbol,
  }) : _repository = repository,
       _favorites = favorites {
    _favorites.addListener(notifyListeners);
  }

  final StockRepository _repository;
  final FavoritesStore _favorites;
  final String symbol;

  Stock? _stock;
  Quote? _quote;
  List<DailyPrice> _prices = const <DailyPrice>[];

  LoadState _state = LoadState.initial;
  String? _errorMessage;
  ChartPeriod _period = ChartPeriod.oneMonth;
  bool _isPeriodLoading = false;

  LoadState get state => _state;
  String? get errorMessage => _errorMessage;
  ChartPeriod get period => _period;

  /// 기간 탭을 바꿔 새 구간을 받아오는 중.
  bool get isPeriodLoading => _isPeriodLoading;

  bool get isFavorite => _favorites.contains(symbol);

  String? get name => _stock?.name;

  /// `005930 · 코스피`
  String? get marketLabel =>
      _stock == null ? null : '${_stock!.symbol} · ${_stock!.exchangeName}';

  String? get priceLabel =>
      _quote == null ? null : fmt.thousands(_quote!.price);

  /// 시안은 현재가 옆 등락을 `▼ 400 (-0.22%)` 로 쓴다 — 목록 행과 표기가 다르다.
  String? get changeLabel =>
      _quote == null ? null : fmt.arrowChangeLabel(_quote!.diff, _quote!.rate);

  PriceTone get tone => _quote?.tone ?? PriceTone.flat;

  String? get openLabel => _quote == null ? null : fmt.thousands(_quote!.open);
  String? get highLabel => _quote == null ? null : fmt.thousands(_quote!.high);
  String? get lowLabel => _quote == null ? null : fmt.thousands(_quote!.low);

  /// 요약 카드의 거래량 · 시가총액은 축약한다. (`29,113천` · `1,063조`)
  String? get volumeLabel => _quote == null ? null : fmt.abbrev(_quote!.volume);
  String? get marketCapLabel =>
      _quote == null ? null : fmt.abbrev(_quote!.marketCap);

  /// 차트는 좌표를 직접 계산해야 해서 숫자 모델을 그대로 넘긴다.
  /// 최신 거래일이 먼저 오므로 그리는 쪽에서 뒤집어 쓴다.
  List<DailyPrice> get chartPrices => _prices;

  List<DailyPriceRowUi> get dailyRows =>
      _prices.map(_toDailyRow).toList(growable: false);

  Future<void> load() async {
    _state = LoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // 메타 · 시세 · 일별 시세는 서로를 기다릴 이유가 없다.
      final results = await Future.wait(<Future<Object>>[
        _repository.fetchStockMeta(symbol),
        _repository.fetchQuotes(<String>[symbol]),
        _repository.fetchDailyPrices(symbol, _period),
      ]);

      _stock = results[0] as Stock;
      _quote = (results[1] as Map<String, Quote>)[symbol];
      _prices = results[2] as List<DailyPrice>;
      _state = LoadState.ready;
    } on Object catch (error) {
      _state = LoadState.failed;
      _errorMessage = _messageOf(error);
    }
    notifyListeners();
  }

  /// 기간 탭 전환은 **latest-wins** 다. 하나의 플래그로 전부 막으면
  /// `1개월 → 3개월` 을 빠르게 눌렀을 때 나중 의도가 무시된다.
  Future<void> changePeriod(ChartPeriod period) async {
    if (_period == period) return;

    _period = period;
    _isPeriodLoading = true;
    notifyListeners();

    try {
      final List<DailyPrice> prices = await _repository.fetchDailyPrices(
        symbol,
        period,
      );
      if (period != _period) return; // 지난 탭의 응답은 버린다
      _prices = prices;
      _errorMessage = null;
    } on Object catch (error) {
      if (period != _period) return;
      _errorMessage = _messageOf(error);
    } finally {
      if (period == _period) {
        _isPeriodLoading = false;
        notifyListeners();
      }
    }
  }

  /// 메타를 받기 전에는 등록할 수 없다. 이름 · 시장이 빈 종목을 관심 목록에 넣으면
  /// 나중에 메타가 도착해도 그 행은 종목코드만 보여준 채로 남는다.
  bool get canToggleFavorite => _stock != null;

  /// 여기서 해제하고 돌아가면 관심 목록에도 반영된다 — 같은 store 를 본다.
  bool toggleFavorite() {
    final Stock? stock = _stock;
    if (stock == null) return false;
    return _favorites.toggle(stock);
  }

  DailyPriceRowUi _toDailyRow(DailyPrice price) => DailyPriceRowUi(
    dateLabel: fmt.monthDay(price.date),
    closeLabel: fmt.thousands(price.close),
    diffLabel: fmt.signedThousands(price.diff),
    volumeLabel: fmt.thousands(price.volume),
    tone: price.tone,
  );

  static String _messageOf(Object error) =>
      error is FormatException ? '시세를 읽지 못했습니다' : '시세를 불러오지 못했습니다';

  @override
  void dispose() {
    _favorites.removeListener(notifyListeners);
    super.dispose();
  }
}
