import 'package:flutter/foundation.dart';

import '../../core/format.dart';
import '../../data/model/price_tone.dart';
import '../../data/model/quote.dart';
import '../../data/model/stock.dart';
import '../../data/repository/stock_repository.dart';
import '../../state/favorites_store.dart';
import '../common/load_state.dart';
import 'watchlist_ui_model.dart';
import 'watchlist_sort.dart';

/// 관심 화면의 상태와 계산을 맡는다. View 는 정렬 · 포맷을 하지 않는다.
class WatchlistViewModel extends ChangeNotifier {
  WatchlistViewModel({
    required StockRepository repository,
    required FavoritesStore favorites,
  }) : _repository = repository,
       _favorites = favorites {
    _favorites.addListener(_onFavoritesChanged);
  }

  final StockRepository _repository;
  final FavoritesStore _favorites;

  /// symbol 로 바로 찾을 수 있게 둔다. 관심 목록이 바뀌어도 받아둔 시세는 남긴다.
  final Map<String, Quote> _quotes = <String, Quote>{};

  LoadState _state = LoadState.initial;
  String? _errorMessage;
  bool _isRefreshing = false;

  /// 조회 중에 등록된 종목이 있으면 켜 둔다. 지금 나간 요청에는 그 종목이
  /// 들어가지 못했으므로 요청이 끝난 뒤 한 번 더 받아야 한다.
  bool _reloadRequested = false;
  WatchlistSort _sort = WatchlistSort.price;

  LoadState get state => _state;

  /// `failed` 에서만 의미를 갖는다.
  String? get errorMessage => _errorMessage;

  /// 기존 목록을 보여주며 갱신하는 중.
  bool get isRefreshing => _isRefreshing;

  WatchlistSort get sort => _sort;

  /// 빈 상태는 `ready && rows.isEmpty` 로 판단한다.
  List<WatchlistRowUi> get rows => _buildRows();

  Future<void> load() async {
    _reloadRequested = false;

    if (_favorites.isEmpty) {
      _quotes.clear();
      _state = LoadState.ready;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _state = LoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _fetchQuotes();
      _state = LoadState.ready;
    } on Object catch (error) {
      _state = LoadState.failed;
      _errorMessage = _messageOf(error);
    }
    notifyListeners();

    if (_reloadRequested) await load();
  }

  /// 상단 새로고침. 진행 중이면 같은 요청을 겹치지 않는다.
  Future<void> refresh() async {
    if (_isRefreshing || _favorites.isEmpty) return;

    _isRefreshing = true;
    notifyListeners();

    try {
      await _fetchQuotes();
      _state = LoadState.ready;
      _errorMessage = null;
    } on Object catch (error) {
      // 이미 보여주던 목록은 남기고 실패만 알린다.
      if (_quotes.isEmpty) {
        _state = LoadState.failed;
        _errorMessage = _messageOf(error);
      }
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  void changeSort(WatchlistSort sort) {
    if (_sort == sort) return;
    _sort = sort;
    notifyListeners();
  }

  /// 관심 종목을 한 번의 요청으로 조회한다.
  Future<void> _fetchQuotes() async {
    final Map<String, Quote> received = await _repository.fetchQuotes(
      _favorites.symbols,
    );
    _quotes.addAll(received);
  }

  void _onFavoritesChanged() {
    // 해제한 종목의 시세는 버린다.
    _quotes.removeWhere((String symbol, _) => !_favorites.contains(symbol));

    // 관심이 비면 불러올 것이 없다. 실패 상태를 들고 있으면 빈 상태 대신
    // 네트워크 오류 화면이 계속 남는다.
    if (_favorites.isEmpty && _state == LoadState.failed) {
      _state = LoadState.ready;
      _errorMessage = null;
    }

    final bool hasNew = _favorites.symbols.any(
      (String symbol) => !_quotes.containsKey(symbol),
    );
    notifyListeners();

    if (!hasNew) return;

    // 조회 중이면 지금 나간 요청이 이 종목을 담지 못했다. 끝난 뒤로 미룬다.
    if (_state == LoadState.loading) {
      _reloadRequested = true;
      return;
    }

    // 새로 등록된 종목은 스켈레톤으로 먼저 보이고, 시세가 도착하면 채워진다.
    load();
  }

  List<WatchlistRowUi> _buildRows() {
    final List<WatchlistRowUi> rows = _favorites.stocks
        .map(_toRow)
        .toList(growable: true);
    rows.sort(_compare);
    return List<WatchlistRowUi>.unmodifiable(rows);
  }

  WatchlistRowUi _toRow(Stock stock) {
    final Quote? quote = _quotes[stock.symbol];
    if (quote == null) {
      return WatchlistRowUi(
        symbol: stock.symbol,
        name: stock.name,
        marketLabel: '${stock.symbol} · ${stock.exchangeName}',
        tone: PriceTone.flat,
      );
    }
    return WatchlistRowUi(
      symbol: stock.symbol,
      name: stock.name,
      marketLabel: '${stock.symbol} · ${stock.exchangeName}',
      tone: quote.tone,
      priceLabel: thousands(quote.price),
      changeLabel: changeLabel(quote.diff, quote.rate),
    );
  }

  /// 시세를 받지 못한 행은 값으로 줄을 세울 수 없어 **맨 아래**로 보낸다.
  /// 가나다순은 이름이 있으니 영향이 없다.
  int _compare(WatchlistRowUi a, WatchlistRowUi b) {
    if (_sort != WatchlistSort.name && a.isSkeleton != b.isSkeleton) {
      return a.isSkeleton ? 1 : -1;
    }

    switch (_sort) {
      case WatchlistSort.price:
        return _priceOf(b).compareTo(_priceOf(a));
      case WatchlistSort.changeRate:
        return _rateOf(b).compareTo(_rateOf(a));
      case WatchlistSort.name:
        return a.name.compareTo(b.name);
    }
  }

  int _priceOf(WatchlistRowUi row) => _quotes[row.symbol]?.price ?? 0;

  double _rateOf(WatchlistRowUi row) => _quotes[row.symbol]?.rate ?? 0;

  static String _messageOf(Object error) =>
      error is FormatException ? '시세를 읽지 못했습니다' : '시세를 불러오지 못했습니다';

  @override
  void dispose() {
    _favorites.removeListener(_onFavoritesChanged);
    super.dispose();
  }
}
