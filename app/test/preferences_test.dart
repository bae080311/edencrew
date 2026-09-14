import 'package:edencrew_assignment_starter/data/model/stock.dart';
import 'package:edencrew_assignment_starter/state/favorites_store.dart';
import 'package:edencrew_assignment_starter/state/preferences.dart';
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
}
