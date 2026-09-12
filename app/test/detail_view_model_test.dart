import 'package:edencrew_assignment_starter/data/model/chart_period.dart';
import 'package:edencrew_assignment_starter/data/model/daily_price.dart';
import 'package:edencrew_assignment_starter/data/model/price_tone.dart';
import 'package:edencrew_assignment_starter/data/model/quote.dart';
import 'package:edencrew_assignment_starter/data/model/stock.dart';
import 'package:edencrew_assignment_starter/data/repository/stock_repository.dart';
import 'package:edencrew_assignment_starter/state/favorites_store.dart';
import 'package:edencrew_assignment_starter/ui/common/load_state.dart';
import 'package:edencrew_assignment_starter/ui/detail/detail_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

const samsung = Stock(symbol: '005930', name: '삼성전자', exchangeName: '코스피');

final samsungQuote = Quote(
  symbol: '005930',
  price: 258000,
  previousClose: 269000,
  open: 258000,
  high: 261000,
  low: 257500,
  volume: 29113456,
  listedShares: 5846278608,
);

DailyPrice priceOf(String date, {int close = 257500, int diff = -11500}) =>
    DailyPrice(
      date: date,
      close: close,
      diff: diff,
      open: 258000,
      high: 261000,
      low: 257500,
      volume: 6448323,
    );

/// 기간별 결과와 지연을 제어하는 스텁.
class StubStockRepository implements StockRepository {
  StubStockRepository({
    this.byPeriod = const <ChartPeriod, List<DailyPrice>>{},
    this.delays = const <ChartPeriod, Duration>{},
    this.error,
  });

  final Map<ChartPeriod, List<DailyPrice>> byPeriod;
  final Map<ChartPeriod, Duration> delays;
  final Object? error;

  final List<ChartPeriod> requestedPeriods = <ChartPeriod>[];

  @override
  Future<List<DailyPrice>> fetchDailyPrices(
    String symbol,
    ChartPeriod period,
  ) async {
    requestedPeriods.add(period);
    final Duration? delay = delays[period];
    if (delay != null) await Future<void>.delayed(delay);
    if (error != null) throw error!;
    return byPeriod[period] ?? <DailyPrice>[priceOf('20260911')];
  }

  @override
  Future<Stock> fetchStockMeta(String symbol) async {
    if (error != null) throw error!;
    return samsung;
  }

  @override
  Future<Map<String, Quote>> fetchQuotes(List<String> symbols) async {
    if (error != null) throw error!;
    return <String, Quote>{'005930': samsungQuote};
  }

  @override
  Future<List<Stock>> searchStocks(String query) => throw UnimplementedError();
}

void main() {
  late FavoritesStore favorites;

  setUp(() => favorites = FavoritesStore());

  DetailViewModel viewModelWith(StubStockRepository repository) =>
      DetailViewModel(
        repository: repository,
        favorites: favorites,
        symbol: '005930',
      );

  group('로딩', () {
    test('메타 · 시세 · 일별 시세를 받아 ready 가 된다', () async {
      final viewModel = viewModelWith(StubStockRepository());

      await viewModel.load();

      expect(viewModel.state, LoadState.ready);
      expect(viewModel.name, '삼성전자');
      expect(viewModel.marketLabel, '005930 · 코스피');
    });

    test('실패하면 failed 와 문구를 남긴다', () async {
      final viewModel = viewModelWith(
        StubStockRepository(error: Exception('network')),
      );

      await viewModel.load();

      expect(viewModel.state, LoadState.failed);
      expect(viewModel.errorMessage, '시세를 불러오지 못했습니다');
    });
  });

  group('현재가와 등락', () {
    test('현재가 · 등락 · 방향을 담는다', () async {
      final viewModel = viewModelWith(StubStockRepository());

      await viewModel.load();

      expect(viewModel.priceLabel, '258,000');
      expect(viewModel.changeLabel, '▼ 11,000 (-4.09%)');
      expect(viewModel.tone, PriceTone.down);
    });
  });

  group('요약 카드', () {
    test('시가 · 고가 · 저가는 천 단위로, 거래량 · 시가총액은 축약한다', () async {
      final viewModel = viewModelWith(StubStockRepository());

      await viewModel.load();

      expect(viewModel.openLabel, '258,000');
      expect(viewModel.highLabel, '261,000');
      expect(viewModel.lowLabel, '257,500');
      expect(viewModel.volumeLabel, '29,113천');
      expect(viewModel.marketCapLabel, '1,508조');
    });
  });

  group('일별 시세 표', () {
    test('날짜는 MM.DD, 등락은 부호와 방향을 함께 준다', () async {
      final viewModel = viewModelWith(
        StubStockRepository(
          byPeriod: {
            ChartPeriod.oneMonth: <DailyPrice>[
              priceOf('20260911'),
              priceOf('20260910', close: 269000, diff: 14500),
              priceOf('20260909', close: 269500, diff: 0),
            ],
          },
        ),
      );

      await viewModel.load();
      final rows = viewModel.dailyRows;

      expect(rows[0].dateLabel, '09.11');
      expect(rows[0].closeLabel, '257,500');
      expect(rows[0].diffLabel, '-11,500');
      expect(rows[0].tone, PriceTone.down);
      expect(rows[0].volumeLabel, '6,448,323');

      expect(rows[1].diffLabel, '+14,500');
      expect(rows[1].tone, PriceTone.up);

      expect(rows[2].diffLabel, '0');
      expect(rows[2].tone, PriceTone.flat);
    });
  });

  group('기간 탭', () {
    test('기본은 1개월이고 처음 조회에 쓰인다', () async {
      final repository = StubStockRepository();
      final viewModel = viewModelWith(repository);

      await viewModel.load();

      expect(viewModel.period, ChartPeriod.oneMonth);
      expect(repository.requestedPeriods, [ChartPeriod.oneMonth]);
    });

    test('탭을 바꾸면 그 기간으로 다시 받는다', () async {
      final repository = StubStockRepository(
        byPeriod: {
          ChartPeriod.threeMonths: <DailyPrice>[
            priceOf('20260911'),
            priceOf('20260910'),
          ],
        },
      );
      final viewModel = viewModelWith(repository);
      await viewModel.load();

      await viewModel.changePeriod(ChartPeriod.threeMonths);

      expect(viewModel.period, ChartPeriod.threeMonths);
      expect(viewModel.dailyRows.length, 2);
      expect(repository.requestedPeriods, [
        ChartPeriod.oneMonth,
        ChartPeriod.threeMonths,
      ]);
    });

    test('같은 탭을 다시 누르면 조회하지 않는다', () async {
      final repository = StubStockRepository();
      final viewModel = viewModelWith(repository);
      await viewModel.load();
      repository.requestedPeriods.clear();

      await viewModel.changePeriod(ChartPeriod.oneMonth);

      expect(repository.requestedPeriods, isEmpty);
    });

    test('latest-wins — 빠르게 두 번 바꾸면 나중 탭의 결과가 남는다', () async {
      final repository = StubStockRepository(
        byPeriod: {
          ChartPeriod.threeMonths: <DailyPrice>[
            priceOf('20260901'),
            priceOf('20260831'),
            priceOf('20260830'),
          ],
          ChartPeriod.oneYear: <DailyPrice>[priceOf('20260911')],
        },
        delays: {ChartPeriod.threeMonths: const Duration(milliseconds: 80)},
      );
      final viewModel = viewModelWith(repository);
      await viewModel.load();

      final slow = viewModel.changePeriod(ChartPeriod.threeMonths);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final fast = viewModel.changePeriod(ChartPeriod.oneYear);
      await Future.wait([slow, fast]);

      expect(viewModel.period, ChartPeriod.oneYear);
      expect(viewModel.dailyRows.length, 1);
      expect(viewModel.isPeriodLoading, isFalse);
    });
  });

  group('관심 토글', () {
    test('여기서 등록하면 store 에 반영된다', () async {
      final viewModel = viewModelWith(StubStockRepository());
      await viewModel.load();

      expect(viewModel.isFavorite, isFalse);
      expect(viewModel.toggleFavorite(), isTrue);

      expect(viewModel.isFavorite, isTrue);
      expect(favorites.contains('005930'), isTrue);
      expect(favorites.stocks.single.name, '삼성전자');
    });

    test('해제하면 관심 목록에서도 빠진다', () async {
      favorites.toggle(samsung);
      final viewModel = viewModelWith(StubStockRepository());
      await viewModel.load();

      expect(viewModel.toggleFavorite(), isFalse);

      expect(favorites.isEmpty, isTrue);
      expect(viewModel.isFavorite, isFalse);
    });

    test('다른 화면에서 관심이 바뀌면 별 아이콘도 따라 바뀐다', () async {
      final viewModel = viewModelWith(StubStockRepository());
      await viewModel.load();

      favorites.toggle(samsung);

      expect(viewModel.isFavorite, isTrue);
    });
  });

  group('차트', () {
    test('좌표를 계산할 수 있게 숫자 모델을 그대로 준다', () async {
      final viewModel = viewModelWith(StubStockRepository());

      await viewModel.load();

      expect(viewModel.chartPrices.single.close, 257500);
      expect(viewModel.chartPrices.single.high, 261000);
      expect(viewModel.chartPrices.single.tone, PriceTone.down);
    });
  });

  group('관심 등록', () {
    test('메타를 받기 전에는 등록할 수 없다', () {
      final FavoritesStore favorites = FavoritesStore();
      final DetailViewModel viewModel = DetailViewModel(
        repository: StubStockRepository(),
        favorites: favorites,
        symbol: '005930',
      );

      expect(viewModel.canToggleFavorite, isFalse);
      expect(viewModel.toggleFavorite(), isFalse);
      // 이름 · 시장이 빈 종목이 들어가면 관심 목록이 종목코드만 보여준 채로 남는다.
      expect(favorites.isEmpty, isTrue);
    });

    test('메타를 받은 뒤에는 이름과 시장이 함께 등록된다', () async {
      final FavoritesStore favorites = FavoritesStore();
      final DetailViewModel viewModel = DetailViewModel(
        repository: StubStockRepository(),
        favorites: favorites,
        symbol: '005930',
      );
      await viewModel.load();

      expect(viewModel.canToggleFavorite, isTrue);
      expect(viewModel.toggleFavorite(), isTrue);
      expect(favorites.stocks.single.name, '삼성전자');
      expect(favorites.stocks.single.exchangeName, '코스피');
    });
  });
}
