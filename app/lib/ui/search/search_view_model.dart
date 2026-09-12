import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/model/stock.dart';
import '../../data/repository/stock_repository.dart';
import '../../state/favorites_store.dart';
import '../common/load_state.dart';
import 'search_ui_model.dart';

/// 검색 화면의 상태와 계산을 맡는다.
class SearchViewModel extends ChangeNotifier {
  SearchViewModel({
    required StockRepository repository,
    required FavoritesStore favorites,
    Duration debounce = const Duration(milliseconds: 300),
  }) : _repository = repository,
       _favorites = favorites,
       _debounce = debounce {
    _favorites.addListener(notifyListeners);
  }

  final StockRepository _repository;
  final FavoritesStore _favorites;
  final Duration _debounce;

  static const int _queryLabelMaxLength = 20;

  Timer? _debounceTimer;

  /// 늦게 도착한 응답이 최신 결과를 덮지 않게 하는 표식.
  int _requestId = 0;

  String _query = '';
  LoadState _state = LoadState.initial;
  String? _errorMessage;
  List<Stock> _results = const <Stock>[];

  String get query => _query;
  LoadState get state => _state;
  String? get errorMessage => _errorMessage;

  /// 결과 없음 문구에 그대로 들어가는 검색어.
  ///
  /// 입력 길이에 제한이 없어 원문을 그대로 넣으면 뒤 문장(`...찾지 못했습니다.`)이
  /// 화면 밖으로 밀린다. 문장이 먼저 읽혀야 하므로 검색어 쪽을 자른다.
  String get queryLabel {
    final String query = _query.trim();
    if (query.length <= _queryLabelMaxLength) return query;
    return '${query.substring(0, _queryLabelMaxLength)}…';
  }

  /// 결과 없음은 `ready && rows.isEmpty` 로 파생시킨다.
  List<SearchRowUi> get rows =>
      _results.map(_toRow).toList(growable: false);

  /// 한 글자마다 요청하지 않는다. 마지막 입력만 살아 남는다.
  void onQueryChanged(String query) {
    _query = query;
    _debounceTimer?.cancel();
    // 입력이 바뀐 순간 진행 중인 요청을 무효로 만든다. 디바운스가 끝날 때까지
    // 미루면 그 사이 도착한 옛 응답이 새 입력 아래에 그대로 뜬다.
    _requestId++;

    if (query.trim().isEmpty) {
      // 입력을 지우면 초기 상태로 돌아간다.
      _results = const <Stock>[];
      _state = LoadState.initial;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    notifyListeners();
    _debounceTimer = Timer(_debounce, () => _search(query));
  }

  void clearQuery() => onQueryChanged('');

  /// 관심 등록 · 해제. **등록됐는지** 돌려줘 View 가 토스트 문구를 가른다.
  bool toggleFavorite(String symbol) {
    final Stock stock = _results.firstWhere(
      (Stock result) => result.symbol == symbol,
      orElse: () => throw StateError('검색 결과에 없는 종목이다: $symbol'),
    );
    return _favorites.toggle(stock);
  }

  Future<void> _search(String query) async {
    final int requestId = ++_requestId;
    _state = LoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<Stock> results = await _repository.searchStocks(query);
      if (requestId != _requestId) return; // 지난 요청의 응답은 버린다
      _results = results;
      _state = LoadState.ready;
    } on Object {
      if (requestId != _requestId) return;
      _results = const <Stock>[];
      _state = LoadState.failed;
      _errorMessage = '검색에 실패했습니다';
    }
    notifyListeners();
  }

  SearchRowUi _toRow(Stock stock) {
    final String keyword = _query.trim();
    final int start = keyword.isEmpty
        ? -1
        : stock.name.toLowerCase().indexOf(keyword.toLowerCase());

    return SearchRowUi(
      symbol: stock.symbol,
      name: stock.name,
      marketLabel: '${stock.symbol} · ${stock.exchangeName}',
      isFavorite: _favorites.contains(stock.symbol),
      highlightStart: start,
      highlightEnd: start < 0 ? -1 : start + keyword.length,
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _favorites.removeListener(notifyListeners);
    super.dispose();
  }
}
