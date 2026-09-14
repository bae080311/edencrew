import 'package:flutter/foundation.dart';

import '../data/model/stock.dart';
import 'preferences.dart';

/// 관심 종목의 **단일 원천**. 세 화면이 같은 객체를 본다.
///
/// 화면마다 목록 사본을 두면 동기화 코드를 세 곳에 짜야 하고 한 곳을 빠뜨리면
/// 어긋난다. 정렬 기준은 화면의 관심사라 여기 두지 않는다.
///
/// symbol 만 담지 않고 [Stock] 을 담는 이유 — 관심 목록은 종목명과 시장을 보여줘야
/// 하는데, 등록하는 화면(검색 · 상세)이 이미 그 값을 갖고 있다. symbol 만 담으면
/// 목록을 그릴 때마다 종목 수만큼 메타를 다시 조회해야 한다.
class FavoritesStore extends ChangeNotifier {
  /// [preferences] 를 주면 앱을 껐다 켜도 목록이 남는다. 저장 방식은 여기서만
  /// 다루고 화면은 모른다(`ARCHITECTURE.md` 영속성 절). 테스트는 주지 않는다.
  FavoritesStore({Preferences? preferences}) : _preferences = preferences {
    _stocks.addAll(preferences?.readFavorites() ?? const <Stock>[]);
  }

  final Preferences? _preferences;
  final List<Stock> _stocks = <Stock>[];

  /// 등록한 순서를 유지한다. 화면에 보이는 순서는 ViewModel 이 정렬한다.
  List<Stock> get stocks => List<Stock>.unmodifiable(_stocks);

  /// 시세를 한 번에 조회할 때 쓴다.
  List<String> get symbols =>
      _stocks.map((Stock stock) => stock.symbol).toList(growable: false);

  bool get isEmpty => _stocks.isEmpty;

  bool contains(String symbol) =>
      _stocks.any((Stock stock) => stock.symbol == symbol);

  /// 등록 · 해제를 뒤집고 **등록됐는지** 돌려준다.
  /// 호출한 화면이 토스트 문구(`관심이 등록되었습니다` / `관심이 해제되었습니다`)를 가른다.
  bool toggle(Stock stock) {
    final int before = _stocks.length;
    _stocks.removeWhere((Stock saved) => saved.symbol == stock.symbol);

    final bool added = _stocks.length == before;
    if (added) _stocks.add(stock);

    _save();
    notifyListeners();
    return added;
  }

  /// 목록에서 곧바로 해제할 때. 없는 종목이면 아무 일도 하지 않는다.
  void remove(String symbol) {
    final int before = _stocks.length;
    _stocks.removeWhere((Stock saved) => saved.symbol == symbol);
    if (_stocks.length == before) return;

    _save();
    notifyListeners();
  }

  /// 해제한 종목을 **원래 자리로** 되돌린다. 실행 취소용이다.
  /// 맨 뒤에 붙이면 등록 순서가 바뀌어 `가나다순` 이 아닌 정렬에서 자리가 달라진다.
  void insert(int index, Stock stock) {
    if (contains(stock.symbol)) return;
    _stocks.insert(index.clamp(0, _stocks.length), stock);
    _save();
    notifyListeners();
  }

  /// 해제 전 위치. 실행 취소가 원래 자리를 알아야 한다.
  int indexOf(String symbol) =>
      _stocks.indexWhere((Stock saved) => saved.symbol == symbol);

  void _save() => _preferences?.writeFavorites(_stocks);
}
