import 'package:edencrew_assignment_starter/data/model/stock.dart';
import 'package:edencrew_assignment_starter/state/favorites_store.dart';
import 'package:flutter_test/flutter_test.dart';

const samsung = Stock(
  symbol: '005930',
  name: '삼성전자',
  exchangeName: '코스피',
);
const hynix = Stock(
  symbol: '000660',
  name: 'SK하이닉스',
  exchangeName: '코스피',
);
const naver = Stock(symbol: '035420', name: 'NAVER', exchangeName: '코스피');

void main() {
  late FavoritesStore store;

  setUp(() => store = FavoritesStore());

  test('처음에는 비어 있다', () {
    expect(store.isEmpty, isTrue);
    expect(store.stocks, isEmpty);
    expect(store.symbols, isEmpty);
  });

  test('토글하면 등록되고 다시 토글하면 해제된다', () {
    expect(store.toggle(samsung), isTrue);
    expect(store.contains('005930'), isTrue);

    expect(store.toggle(samsung), isFalse);
    expect(store.contains('005930'), isFalse);
    expect(store.isEmpty, isTrue);
  });

  test('종목명과 시장을 함께 들고 있다 — 목록을 그릴 때 메타를 다시 안 부른다', () {
    store.toggle(samsung);

    expect(store.stocks.single.name, '삼성전자');
    expect(store.stocks.single.exchangeName, '코스피');
  });

  test('같은 종목이 두 번 들어가지 않는다', () {
    store.toggle(samsung);
    store.toggle(samsung); // 해제
    store.toggle(samsung); // 재등록

    expect(store.symbols, ['005930']);
  });

  test('등록한 순서를 유지한다', () {
    store.toggle(samsung);
    store.toggle(hynix);
    store.toggle(naver);

    expect(store.symbols, ['005930', '000660', '035420']);
  });

  test('중간 항목을 해제해도 나머지 순서는 그대로다', () {
    store.toggle(samsung);
    store.toggle(hynix);
    store.toggle(naver);

    store.toggle(hynix);

    expect(store.symbols, ['005930', '035420']);
  });

  test('해제한 종목을 다시 등록하면 맨 뒤로 간다', () {
    store.toggle(samsung);
    store.toggle(hynix);

    store.toggle(samsung);
    store.toggle(samsung);

    expect(store.symbols, ['000660', '005930']);
  });

  test('remove 는 symbol 만으로 해제한다', () {
    store.toggle(samsung);
    store.toggle(hynix);

    store.remove('005930');

    expect(store.symbols, ['000660']);
  });

  test('없는 종목을 remove 하면 알리지 않는다', () {
    int notified = 0;
    store.addListener(() => notified++);

    store.remove('999999');

    expect(notified, 0);
  });

  test('바뀔 때마다 알린다', () {
    int notified = 0;
    store.addListener(() => notified++);

    store.toggle(samsung);
    store.toggle(samsung);

    expect(notified, 2);
  });

  test('돌려주는 목록은 밖에서 고칠 수 없다', () {
    store.toggle(samsung);

    expect(() => store.stocks.add(hynix), throwsUnsupportedError);
  });
}
