import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/model/stock.dart';
import '../../data/repository/stock_repository.dart';
import '../../state/favorites_store.dart';
import '../../state/preferences.dart';
import '../common/load_state.dart';
import '../../core/debug_log.dart';
import 'search_ui_model.dart';

/// 검색 화면의 상태와 계산을 맡는다.
class SearchViewModel extends ChangeNotifier {
  SearchViewModel({
    required StockRepository repository,
    required FavoritesStore favorites,
    Duration debounce = const Duration(milliseconds: 300),
    Preferences? preferences,
  }) : _repository = repository,
       _favorites = favorites,
       _debounce = debounce,
       _preferences = preferences {
    _recentQueries = preferences?.readRecentQueries() ?? const <String>[];
    _favorites.addListener(notifyListeners);
  }

  final StockRepository _repository;
  final FavoritesStore _favorites;
  final Duration _debounce;
  final Preferences? _preferences;

  /// 최근 검색어. 최신이 앞이다.
  List<String> _recentQueries = const <String>[];

  static const int _queryLabelMaxLength = 20;

  Timer? _debounceTimer;

  /// 늦게 도착한 응답이 최신 결과를 덮지 않게 하는 표식.
  int _requestId = 0;

  String _query = '';

  /// **지금 화면에 떠 있는 결과를 만든 검색어.** `_query` 와 다를 수 있다 —
  /// 입력이 바뀌어도 받아둔 결과는 다음 응답이 올 때까지 그대로 남기 때문이다.
  /// 하이라이트와 최근 검색어 기록은 화면에 보이는 것과 맞아야 하므로 이쪽을 쓴다.
  String _resultsQuery = '';
  LoadState _state = LoadState.initial;
  String? _errorMessage;
  List<Stock> _results = const <Stock>[];

  String get query => _query;

  List<String> get recentQueries => _recentQueries;

  /// 검색어는 **결과를 눌렀을 때만** 남긴다. 디바운스가 끝날 때마다 남기면
  /// `삼` · `삼성` 처럼 지나가는 입력이 목록을 채운다. 결과를 눌렀다는 것은
  /// 그 검색어가 원하던 것을 찾아줬다는 뜻이다.
  void recordQuery() {
    // 누른 행을 만든 검색어를 남긴다. `_query` 를 쓰면 `삼성` 결과가 떠 있는 동안
    // `카카오` 를 입력하고 그 행을 누를 때 `카카오` 가 성공한 검색어로 남는다.
    final String query = _resultsQuery.trim();
    // 결과가 없는 검색어는 남기지 않는다. 다시 눌러도 빈 화면만 나온다.
    if (query.isEmpty || _results.isEmpty) return;

    final List<String> next = <String>[
      query,
      ..._recentQueries.where((String saved) => saved != query),
    ];
    _recentQueries = next
        .take(Preferences.recentQueryLimit)
        .toList(growable: false);
    _preferences?.writeRecentQueries(_recentQueries);
    notifyListeners();
  }

  void removeRecentQuery(String query) {
    _recentQueries = _recentQueries
        .where((String saved) => saved != query)
        .toList(growable: false);
    _preferences?.writeRecentQueries(_recentQueries);
    notifyListeners();
  }

  void clearRecentQueries() {
    if (_recentQueries.isEmpty) return;
    _recentQueries = const <String>[];
    _preferences?.writeRecentQueries(_recentQueries);
    notifyListeners();
  }

  LoadState get state => _state;

  /// `failed` 일 때 화면에 그대로 나가는 문구. 기본값은 ViewModel 이 정한다.
  String get errorMessage => _errorMessage ?? '검색에 실패했습니다';

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
  List<SearchRowUi> get rows => _results.map(_toRow).toList(growable: false);

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
      _resultsQuery = '';
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
      _resultsQuery = query;
      _state = LoadState.ready;
    } on Object catch (error, stackTrace) {
      if (requestId != _requestId) return;
      logSwallowed('검색', error, stackTrace);
      _results = const <Stock>[];
      _resultsQuery = '';
      _state = LoadState.failed;
      _errorMessage = '검색에 실패했습니다';
    }
    notifyListeners();
  }

  SearchRowUi _toRow(Stock stock) {
    // 강조도 화면에 보이는 결과를 만든 검색어로 건다.
    final String keyword = _resultsQuery.trim();
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
