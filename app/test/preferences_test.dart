import 'package:edencrew_assignment_starter/data/model/stock.dart';
import 'package:edencrew_assignment_starter/state/favorites_store.dart';
import 'package:edencrew_assignment_starter/state/preferences.dart';
import 'package:edencrew_assignment_starter/ui/watchlist/watchlist_sort.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Stock samsung = Stock(
  symbol: '005930',
  name: '삼성전자',
  exchangeName: '코스피',
);
const Stock hynix = Stock(
  symbol: '000660',
  name: 'SK하이닉스',
  exchangeName: '코스피',
);

Future<Preferences> prefsWith([Map<String, Object> seed = const {}]) async {
  SharedPreferences.setMockInitialValues(seed);
  return Preferences.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('관심 목록이 저장되고 다시 읽힌다', () async {
    final Preferences prefs = await prefsWith();

    FavoritesStore(preferences: prefs)
      ..toggle(samsung)
      ..toggle(hynix);

    // 같은 저장소를 보는 새 스토어 — 앱을 껐다 켠 것과 같다.
    final FavoritesStore restored = FavoritesStore(preferences: prefs);
    expect(restored.symbols, <String>[
      '005930',
      '000660',
    ], reason: '등록 순서까지 그대로 남아야 한다');
    expect(restored.stocks.first.name, '삼성전자');
    expect(restored.stocks.first.exchangeName, '코스피');
  });

  test('해제하면 저장본에서도 빠진다', () async {
    final Preferences prefs = await prefsWith();
    FavoritesStore(preferences: prefs)
      ..toggle(samsung)
      ..toggle(hynix)
      ..remove('005930');

    expect(FavoritesStore(preferences: prefs).symbols, <String>['000660']);
  });

  test('저장값이 깨져 있으면 빈 목록으로 시작한다', () async {
    final Preferences prefs = await prefsWith(<String, Object>{
      'flutter.favorites': '{ 이건 JSON 이 아니다',
    });

    expect(FavoritesStore(preferences: prefs).isEmpty, isTrue);
  });

  test('최근 검색어는 순서 그대로 저장되고 개수 제한이 걸린다', () async {
    final Preferences prefs = await prefsWith();

    prefs.writeRecentQueries(<String>['삼성전자', '카카오']);
    expect(prefs.readRecentQueries(), <String>['삼성전자', '카카오']);

    // 중복 제거는 `SearchViewModel.recordQuery` 몫이고, 개수 제한은 저장소가 건다.
    prefs.writeRecentQueries(
      List<String>.generate(
        Preferences.recentQueryLimit + 5,
        (int i) => '검색$i',
      ),
    );
    expect(prefs.readRecentQueries().length, Preferences.recentQueryLimit);
  });

  test('정렬 기준이 저장되고 다시 읽힌다', () async {
    final Preferences prefs = await prefsWith();
    expect(prefs.readSort(), isNull);

    prefs.writeSort('changeRate');
    expect(prefs.readSort(), 'changeRate');
  });

  test('읽기가 다른 타입을 만나도 빈 값으로 시작한다', () async {
    // 이전 버전이 같은 키에 다른 형태를 남긴 경우.
    final Preferences prefs = await prefsWith(<String, Object>{
      'flutter.recent_queries': 'string 이 아니라 목록이어야 한다',
    });

    expect(prefs.readRecentQueries(), isEmpty);
  });

  test('정렬 기준이 지금 enum 에 없으면 무시한다', () async {
    final Preferences prefs = await prefsWith(<String, Object>{
      'flutter.watchlist_sort': '예전이름',
    });

    // 저장소는 값을 그대로 돌려주고, 해석은 ViewModel 이 한다.
    expect(prefs.readSort(), '예전이름');
    expect(WatchlistSort.values.asNameMap()['예전이름'], isNull);
  });
}
