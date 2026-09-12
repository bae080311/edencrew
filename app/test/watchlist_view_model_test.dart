import 'package:edencrew_assignment_starter/data/model/chart_period.dart';
import 'package:edencrew_assignment_starter/data/model/daily_price.dart';
import 'package:edencrew_assignment_starter/data/model/price_tone.dart';
import 'package:edencrew_assignment_starter/data/model/quote.dart';
import 'package:edencrew_assignment_starter/data/model/stock.dart';
import 'package:edencrew_assignment_starter/data/repository/stock_repository.dart';
import 'package:edencrew_assignment_starter/state/favorites_store.dart';
import 'package:edencrew_assignment_starter/ui/common/load_state.dart';
import 'package:edencrew_assignment_starter/ui/watchlist/watchlist_sort.dart';
import 'package:edencrew_assignment_starter/ui/watchlist/watchlist_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

const samsung = Stock(symbol: '005930', name: '삼성전자', exchangeName: '코스피');
const hynix = Stock(symbol: '000660', name: 'SK하이닉스', exchangeName: '코스피');
const naver = Stock(symbol: '035420', name: 'NAVER', exchangeName: '코스피');

Quote quoteOf(String symbol, {required int price, required int previousClose}) =>
    Quote(
      symbol: symbol,
      price: price,
      previousClose: previousClose,
      open: price,
      high: price,
      low: price,
      volume: 0,
      listedShares: 1000,
    );

/// 요청 횟수와 실패를 제어하려고 둔 스텁.
class StubStockRepository implements StockRepository {
  StubStockRepository({
    this.quotes = const <String, Quote>{},
    this.error,
    this.delay,
  });

  final Map<String, Quote> quotes;

  /// 도중에 바꿔 가며 "처음엔 성공, 다음엔 실패" 를 만든다.
  Object? error;

  /// 요청이 나간 뒤 관심 목록이 바뀌는 상황을 만들려면 응답이 바로 끝나면 안 된다.
  final Duration? delay;

  final List<List<String>> requests = <List<String>>[];

  int _inFlight = 0;

  /// 같은 조회가 겹쳐 나갔는지 본다. 요청 횟수만 세면 겹침을 못 잡는다.
  int maxInFlight = 0;

  @override
  Future<Map<String, Quote>> fetchQuotes(List<String> symbols) async {
    requests.add(List<String>.of(symbols));
    _inFlight++;
    if (_inFlight > maxInFlight) maxInFlight = _inFlight;
    try {
      if (delay != null) await Future<void>.delayed(delay!);
      if (error != null) throw error!;
      return <String, Quote>{
        for (final String symbol in symbols)
          if (quotes.containsKey(symbol)) symbol: quotes[symbol]!,
      };
    } finally {
      _inFlight--;
    }
  }

  @override
  Future<List<Stock>> searchStocks(String query) => throw UnimplementedError();

  @override
  Future<Stock> fetchStockMeta(String symbol) => throw UnimplementedError();

  @override
  Future<List<DailyPrice>> fetchDailyPrices(
    String symbol,
    ChartPeriod period,
  ) => throw UnimplementedError();
}

void main() {
  late FavoritesStore favorites;

  setUp(() => favorites = FavoritesStore());

  WatchlistViewModel viewModelWith(StubStockRepository repository) =>
      WatchlistViewModel(repository: repository, favorites: favorites);

  group('빈 상태', () {
    test('관심 종목이 없으면 조회하지 않고 ready 로 둔다', () async {
      final repository = StubStockRepository();
      final viewModel = viewModelWith(repository);

      await viewModel.load();

      expect(viewModel.state, LoadState.ready);
      expect(viewModel.rows, isEmpty);
      expect(repository.requests, isEmpty);
    });
  });

  group('로딩', () {
    test('initial → loading → ready 로 옮겨간다', () async {
      favorites.toggle(samsung);
      final viewModel = viewModelWith(
        StubStockRepository(
          quotes: {'005930': quoteOf('005930', price: 258000, previousClose: 269000)},
        ),
      );
      expect(viewModel.state, LoadState.initial);

      final states = <LoadState>[];
      viewModel.addListener(() => states.add(viewModel.state));

      await viewModel.load();

      expect(states.first, LoadState.loading);
      expect(viewModel.state, LoadState.ready);
    });

    test('관심 종목을 한 번의 요청으로 조회한다', () async {
      favorites.toggle(samsung);
      favorites.toggle(hynix);
      favorites.toggle(naver);
      final repository = StubStockRepository();
      final viewModel = viewModelWith(repository);

      await viewModel.load();

      expect(repository.requests.length, 1);
      expect(repository.requests.single, ['005930', '000660', '035420']);
    });

    test('실패하면 failed 와 문구를 남긴다', () async {
      favorites.toggle(samsung);
      final viewModel = viewModelWith(
        StubStockRepository(error: Exception('network')),
      );

      await viewModel.load();

      expect(viewModel.state, LoadState.failed);
      expect(viewModel.errorMessage, '시세를 불러오지 못했습니다');
    });
  });

  group('행 정보', () {
    test('종목명 · 종목코드 · 시장 · 현재가 · 등락을 담는다', () async {
      favorites.toggle(samsung);
      final viewModel = viewModelWith(
        StubStockRepository(
          quotes: {'005930': quoteOf('005930', price: 258000, previousClose: 269000)},
        ),
      );

      await viewModel.load();
      final row = viewModel.rows.single;

      expect(row.name, '삼성전자');
      expect(row.marketLabel, '005930 · 코스피');
      expect(row.priceLabel, '258,000');
      expect(row.changeLabel, '-11,000 (-4.09%)');
      expect(row.tone, PriceTone.down);
      expect(row.isSkeleton, isFalse);
    });

    test('시세를 못 받은 행은 스켈레톤이다', () async {
      favorites.toggle(samsung);
      final viewModel = viewModelWith(StubStockRepository());

      await viewModel.load();
      final row = viewModel.rows.single;

      expect(row.isSkeleton, isTrue);
      expect(row.priceLabel, isNull);
      expect(row.name, '삼성전자');
      expect(row.tone, PriceTone.flat);
    });
  });

  group('정렬', () {
    late WatchlistViewModel viewModel;

    setUp(() async {
      favorites.toggle(samsung); // 258,000 · -4.09%
      favorites.toggle(hynix); // 1,786,000 · -3.62%
      favorites.toggle(naver); // 204,000 · -1.92%
      viewModel = viewModelWith(
        StubStockRepository(
          quotes: {
            '005930': quoteOf('005930', price: 258000, previousClose: 269000),
            '000660': quoteOf('000660', price: 1786000, previousClose: 1853000),
            '035420': quoteOf('035420', price: 204000, previousClose: 208000),
          },
        ),
      );
      await viewModel.load();
    });

    test('기본은 현재가순 — 높은 값이 먼저', () {
      expect(viewModel.sort, WatchlistSort.price);
      expect(viewModel.rows.map((r) => r.symbol), [
        '000660',
        '005930',
        '035420',
      ]);
    });

    test('등락률순 — 덜 떨어진 종목이 먼저', () {
      viewModel.changeSort(WatchlistSort.changeRate);

      expect(viewModel.rows.map((r) => r.symbol), [
        '035420',
        '000660',
        '005930',
      ]);
    });

    test('가나다순', () {
      viewModel.changeSort(WatchlistSort.name);

      expect(viewModel.rows.map((r) => r.name), ['NAVER', 'SK하이닉스', '삼성전자']);
    });

    test('같은 기준을 다시 고르면 알리지 않는다', () {
      int notified = 0;
      viewModel.addListener(() => notified++);

      viewModel.changeSort(WatchlistSort.price);

      expect(notified, 0);
    });
  });

  group('시세를 못 받은 행의 정렬 위치', () {
    test('현재가순 · 등락률순에서는 맨 아래로 보낸다', () async {
      favorites.toggle(samsung);
      favorites.toggle(hynix); // 시세 없음
      final viewModel = viewModelWith(
        StubStockRepository(
          quotes: {'005930': quoteOf('005930', price: 258000, previousClose: 269000)},
        ),
      );
      await viewModel.load();

      expect(viewModel.rows.map((r) => r.symbol), ['005930', '000660']);

      viewModel.changeSort(WatchlistSort.changeRate);
      expect(viewModel.rows.map((r) => r.symbol), ['005930', '000660']);
    });

    test('가나다순에서는 이름으로 줄을 세운다', () async {
      favorites.toggle(samsung);
      favorites.toggle(hynix); // 시세 없음
      final viewModel = viewModelWith(
        StubStockRepository(
          quotes: {'005930': quoteOf('005930', price: 258000, previousClose: 269000)},
        ),
      );
      await viewModel.load();

      viewModel.changeSort(WatchlistSort.name);

      expect(viewModel.rows.map((r) => r.name), ['SK하이닉스', '삼성전자']);
    });
  });

  group('새로고침', () {
    test('진행 중이면 같은 요청을 겹치지 않는다', () async {
      favorites.toggle(samsung);
      final repository = StubStockRepository();
      final viewModel = viewModelWith(repository);
      await viewModel.load();
      repository.requests.clear();

      await Future.wait([viewModel.refresh(), viewModel.refresh()]);

      expect(repository.requests.length, 1);
    });

    test('앞선 조회에 있던 종목이 빠져 오면 받아둔 시세를 지운다', () async {
      favorites.toggle(samsung);
      final repository = StubStockRepository(
        quotes: {
          '005930': quoteOf('005930', price: 258000, previousClose: 269000),
        },
      );
      final viewModel = viewModelWith(repository);
      await viewModel.load();
      expect(viewModel.rows.single.priceLabel, '258,000');

      // 거래정지처럼 다음 응답에서 종목이 빠지는 상황.
      repository.quotes.clear();
      await viewModel.refresh();

      expect(
        viewModel.rows.single.isSkeleton,
        isTrue,
        reason: '멈춘 시세가 최신인 것처럼 남았다',
      );
    });

    test('새로고침 중에 등록한 종목은 새로고침이 끝난 뒤에 조회한다', () async {
      favorites.toggle(samsung);
      final repository = StubStockRepository(
        delay: const Duration(milliseconds: 20),
      );
      final viewModel = viewModelWith(repository);
      await viewModel.load();
      repository.requests.clear();
      repository.maxInFlight = 0;

      final Future<void> refreshing = viewModel.refresh();
      await Future<void>.delayed(Duration.zero);
      favorites.toggle(hynix);
      await refreshing;
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(
        repository.maxInFlight,
        1,
        reason: '새로고침과 재조회가 겹쳐 나가면 늦게 끝난 쪽이 더 새 시세를 덮는다',
      );
      expect(repository.requests.last, containsAll(<String>['005930', '000660']));
    });

    test('실패해도 이미 받아둔 목록은 남긴다', () async {
      favorites.toggle(samsung);
      final quotes = {
        '005930': quoteOf('005930', price: 258000, previousClose: 269000),
      };
      final viewModel = viewModelWith(StubStockRepository(quotes: quotes));
      await viewModel.load();

      final failing = WatchlistViewModel(
        repository: StubStockRepository(error: Exception('network')),
        favorites: favorites,
      );
      await failing.load();

      expect(viewModel.rows.single.priceLabel, '258,000');
      expect(failing.state, LoadState.failed);
    });
  });

  group('관심 목록 변경 반영', () {
    test('등록하면 행이 늘고 시세를 조회한다', () async {
      final repository = StubStockRepository(
        quotes: {'005930': quoteOf('005930', price: 258000, previousClose: 269000)},
      );
      final viewModel = viewModelWith(repository);
      await viewModel.load();

      favorites.toggle(samsung);
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.rows.single.symbol, '005930');
      expect(viewModel.rows.single.priceLabel, '258,000');
    });

    test('해제하면 행과 시세가 함께 빠진다', () async {
      favorites.toggle(samsung);
      final viewModel = viewModelWith(
        StubStockRepository(
          quotes: {'005930': quoteOf('005930', price: 258000, previousClose: 269000)},
        ),
      );
      await viewModel.load();

      favorites.remove('005930');
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.rows, isEmpty);
      expect(viewModel.state, LoadState.ready);
    });
  });

  group('조회 중에 관심이 바뀌면', () {
    test('그 사이 등록한 종목도 시세를 받는다', () async {
      favorites.toggle(samsung);
      final repository = StubStockRepository(
        delay: const Duration(milliseconds: 30),
        quotes: {
          '005930': quoteOf('005930', price: 258000, previousClose: 269000),
          '000660': quoteOf('000660', price: 412500, previousClose: 403000),
        },
      );
      final viewModel = viewModelWith(repository);

      final Future<void> loading = viewModel.load();
      // 첫 요청이 이미 나간 뒤 다른 화면에서 등록한 상황.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      favorites.toggle(hynix);

      await loading;
      await Future<void>.delayed(const Duration(milliseconds: 60));

      final rowOfHynix = viewModel.rows.firstWhere((r) => r.symbol == '000660');
      expect(
        rowOfHynix.isSkeleton,
        isFalse,
        reason: '조회가 끝난 뒤에도 스켈레톤으로 남았다',
      );
      expect(repository.requests.length, 2, reason: '끝난 뒤 한 번만 더 받는다');
    });

    test('실패한 뒤 관심을 모두 해제하면 빈 상태로 돌아간다', () async {
      favorites.toggle(samsung);
      final viewModel = viewModelWith(
        StubStockRepository(error: Exception('network')),
      );
      await viewModel.load();
      expect(viewModel.state, LoadState.failed);

      favorites.remove('005930');
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.rows, isEmpty);
      expect(
        viewModel.state,
        LoadState.ready,
        reason: '관심이 비었는데 네트워크 오류 화면이 남는다',
      );
    });
  });

  group('중복 요청과 부분 실패', () {
    test('받아둔 시세가 있으면 재조회가 실패해도 목록을 남긴다', () async {
      favorites.toggle(samsung);
      final repository = StubStockRepository(
        quotes: {'005930': quoteOf('005930', price: 258000, previousClose: 269000)},
      );
      final viewModel = viewModelWith(repository);
      await viewModel.load();

      // 다른 화면에서 하나 더 등록 → 재조회가 도는데 이번엔 실패한다.
      repository.error = Exception('network');
      favorites.toggle(hynix);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(
        viewModel.state,
        LoadState.ready,
        reason: '멀쩡한 행까지 전체 실패 화면으로 덮었다',
      );
      final rowOfSamsung = viewModel.rows.firstWhere((r) => r.symbol == '005930');
      expect(rowOfSamsung.isSkeleton, isFalse);
    });

    test('조회 중에 누른 새로고침은 같은 조회를 겹치지 않는다', () async {
      favorites.toggle(samsung);
      final repository = StubStockRepository(
        delay: const Duration(milliseconds: 30),
        quotes: {'005930': quoteOf('005930', price: 258000, previousClose: 269000)},
      );
      final viewModel = viewModelWith(repository);

      final Future<void> loading = viewModel.load();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await viewModel.refresh(); // 느린 조회 중에 새로고침을 누른 상황

      await loading;
      expect(repository.requests.length, 1, reason: '조회가 두 번 나갔다');
    });
  });
}
