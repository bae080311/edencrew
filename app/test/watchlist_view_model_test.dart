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
  StubStockRepository({this.quotes = const <String, Quote>{}, this.error});

  final Map<String, Quote> quotes;
  final Object? error;

  final List<List<String>> requests = <List<String>>[];

  @override
  Future<Map<String, Quote>> fetchQuotes(List<String> symbols) async {
    requests.add(List<String>.of(symbols));
    if (error != null) throw error!;
    return <String, Quote>{
      for (final String symbol in symbols)
        if (quotes.containsKey(symbol)) symbol: quotes[symbol]!,
    };
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
}
