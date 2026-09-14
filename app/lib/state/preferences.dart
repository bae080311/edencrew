import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/model/stock.dart';

/// 앱을 껐다 켜도 남아야 하는 값의 저장소.
///
/// 저장 방식이 바뀔 때만 열리는 파일이다 — 화면과 스토어는 `shared_preferences`
/// 라는 이름을 모른다. 저장이 실패해도 앱은 그대로 돌아야 하므로 쓰기는
/// 기다리지 않고, 읽기는 값이 깨져 있으면 빈 값으로 돌려준다.
class Preferences {
  Preferences(this._prefs);

  final SharedPreferences _prefs;

  static const String _favoritesKey = 'favorites';
  static const String _sortKey = 'watchlist_sort';
  static const String _recentQueriesKey = 'recent_queries';

  /// 최근 검색어 보관 개수. 시안에 없는 값이라 한 화면에 들어가는 만큼으로 잡았다.
  static const int recentQueryLimit = 10;

  static Future<Preferences> load() async =>
      Preferences(await SharedPreferences.getInstance());

  List<Stock> readFavorites() {
    final String? raw = _prefs.getString(_favoritesKey);
    if (raw == null) return const <Stock>[];
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return const <Stock>[];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_toStock)
          .whereType<Stock>()
          .toList(growable: false);
    } on FormatException {
      // 이전 버전이 남긴 형식이거나 손상된 값이다. 지우고 빈 목록으로 시작한다.
      return const <Stock>[];
    }
  }

  void writeFavorites(List<Stock> stocks) {
    _prefs.setString(
      _favoritesKey,
      jsonEncode(
        stocks
            .map(
              (Stock stock) => <String, String>{
                'symbol': stock.symbol,
                'name': stock.name,
                'exchangeName': stock.exchangeName,
              },
            )
            .toList(growable: false),
      ),
    );
  }

  String? readSort() => _prefs.getString(_sortKey);

  void writeSort(String name) => _prefs.setString(_sortKey, name);

  List<String> readRecentQueries() =>
      _prefs.getStringList(_recentQueriesKey) ?? const <String>[];

  void writeRecentQueries(List<String> queries) => _prefs.setStringList(
    _recentQueriesKey,
    queries.take(recentQueryLimit).toList(growable: false),
  );

  static Stock? _toStock(Map<String, dynamic> json) {
    final Object? symbol = json['symbol'];
    final Object? name = json['name'];
    final Object? exchangeName = json['exchangeName'];
    if (symbol is! String || name is! String) return null;
    return Stock(
      symbol: symbol,
      name: name,
      exchangeName: exchangeName is String ? exchangeName : '',
    );
  }
}
