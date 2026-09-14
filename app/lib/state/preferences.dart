import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/model/stock.dart';
import '../core/debug_log.dart';

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
    final String? raw = _read(_favoritesKey, _prefs.getString);
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
    _write(
      _favoritesKey,
      () => _prefs.setString(
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
      ),
    );
  }

  String? readSort() => _read(_sortKey, _prefs.getString);

  void writeSort(String name) =>
      _write(_sortKey, () => _prefs.setString(_sortKey, name));

  List<String> readRecentQueries() =>
      _read(_recentQueriesKey, _prefs.getStringList) ?? const <String>[];

  /// 저장된 값이 기대한 타입이 아니면 `getString` 계열이 그대로 던진다.
  /// 이전 버전이 같은 키에 다른 형태를 남겼을 때 앱이 못 뜨면 안 된다.
  T? _read<T>(String key, T? Function(String key) read) {
    try {
      return read(key);
    } on Object catch (error, stackTrace) {
      logSwallowed('저장값을 읽지 못했다 ($key)', error, stackTrace);
      return null;
    }
  }

  void writeRecentQueries(List<String> queries) => _write(
    _recentQueriesKey,
    () => _prefs.setStringList(
      _recentQueriesKey,
      queries.take(recentQueryLimit).toList(growable: false),
    ),
  );

  /// 쓰기는 기다리지 않는다 — 화면이 저장을 기다릴 이유가 없다. 대신 실패를
  /// 흘려보내지 않는다. `await` 없이 두면 예외가 아무 데도 안 걸려 사라진다.
  void _write(String key, Future<bool> Function() write) =>
      unawaited(_writeAndLog(key, write));

  Future<void> _writeAndLog(String key, Future<bool> Function() write) async {
    try {
      if (!await write()) logSwallowed('저장 실패', '$key 에 쓰지 못했다');
    } on Object catch (error, stackTrace) {
      logSwallowed('저장 실패 ($key)', error, stackTrace);
    }
  }

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
