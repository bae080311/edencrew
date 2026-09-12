import 'package:edencrew_assignment_starter/data/model/chart_period.dart';
import 'package:edencrew_assignment_starter/data/model/daily_price.dart';
import 'package:edencrew_assignment_starter/data/model/quote.dart';
import 'package:edencrew_assignment_starter/data/model/stock.dart';
import 'package:edencrew_assignment_starter/data/repository/stock_repository.dart';
import 'package:edencrew_assignment_starter/state/favorites_store.dart';
import 'package:edencrew_assignment_starter/ui/common/load_state.dart';
import 'package:edencrew_assignment_starter/ui/search/search_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

const samsung = Stock(symbol: '005930', name: '삼성전자', exchangeName: '코스피');
const samsungElec = Stock(symbol: '009150', name: '삼성전기', exchangeName: '코스피');
const naver = Stock(symbol: '035420', name: 'NAVER', exchangeName: '코스피');

/// 검색어별 결과와 지연을 제어하는 스텁.
class StubStockRepository implements StockRepository {
  StubStockRepository({
    this.byQuery = const <String, List<Stock>>{},
    this.delays = const <String, Duration>{},
    this.error,
  });

  final Map<String, List<Stock>> byQuery;
  final Map<String, Duration> delays;
  final Object? error;

  final List<String> queries = <String>[];

  @override
  Future<List<Stock>> searchStocks(String query) async {
    queries.add(query);
    final Duration? delay = delays[query];
    if (delay != null) await Future<void>.delayed(delay);
    if (error != null) throw error!;
    return byQuery[query] ?? const <Stock>[];
  }

  @override
  Future<Map<String, Quote>> fetchQuotes(List<String> symbols) =>
      throw UnimplementedError();

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

  SearchViewModel viewModelWith(
    StubStockRepository repository, {
    Duration debounce = const Duration(milliseconds: 10),
  }) => SearchViewModel(
    repository: repository,
    favorites: favorites,
    debounce: debounce,
  );

  group('초기 상태', () {
    test('입력 전에는 조회하지 않는다', () async {
      final repository = StubStockRepository();
      final viewModel = viewModelWith(repository);

      expect(viewModel.state, LoadState.initial);
      expect(viewModel.rows, isEmpty);
      expect(repository.queries, isEmpty);
    });

    test('공백만 입력해도 조회하지 않는다', () async {
      final repository = StubStockRepository();
      final viewModel = viewModelWith(repository);

      viewModel.onQueryChanged('   ');
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(viewModel.state, LoadState.initial);
      expect(repository.queries, isEmpty);
    });

    test('입력을 지우면 초기 상태로 돌아간다', () async {
      final viewModel = viewModelWith(
        StubStockRepository(byQuery: {'삼성': [samsung]}),
      );

      viewModel.onQueryChanged('삼성');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(viewModel.rows, isNotEmpty);

      viewModel.clearQuery();

      expect(viewModel.query, '');
      expect(viewModel.state, LoadState.initial);
      expect(viewModel.rows, isEmpty);
    });
  });

  group('디바운스', () {
    test('연속 입력에서 마지막 것만 조회한다', () async {
      final repository = StubStockRepository(
        byQuery: {'삼성전자': [samsung]},
      );
      final viewModel = viewModelWith(repository);

      viewModel.onQueryChanged('삼');
      viewModel.onQueryChanged('삼성');
      viewModel.onQueryChanged('삼성전자');
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(repository.queries, ['삼성전자']);
      expect(viewModel.rows.single.symbol, '005930');
    });
  });

  group('latest-wins', () {
    test('늦게 온 옛 응답이 최신 결과를 덮지 않는다', () async {
      final repository = StubStockRepository(
        byQuery: {
          '삼성': [samsung, samsungElec],
          'NAVER': [naver],
        },
        delays: {'삼성': const Duration(milliseconds: 80)},
      );
      final viewModel = viewModelWith(repository);

      viewModel.onQueryChanged('삼성');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      viewModel.onQueryChanged('NAVER');
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(viewModel.rows.map((r) => r.symbol), ['035420']);
      expect(viewModel.state, LoadState.ready);
    });
  });

  group('결과 행', () {
    test('종목명 · 종목코드 · 시장을 담는다', () async {
      final viewModel = viewModelWith(
        StubStockRepository(byQuery: {'삼성': [samsung]}),
      );

      viewModel.onQueryChanged('삼성');
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final row = viewModel.rows.single;
      expect(row.name, '삼성전자');
      expect(row.marketLabel, '005930 · 코스피');
      expect(row.isFavorite, isFalse);
    });

    test('검색어와 맞는 구간을 알려준다', () async {
      final viewModel = viewModelWith(
        StubStockRepository(byQuery: {'전자': [samsung]}),
      );

      viewModel.onQueryChanged('전자');
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final row = viewModel.rows.single;
      expect(row.hasHighlight, isTrue);
      expect(row.name.substring(row.highlightStart, row.highlightEnd), '전자');
    });

    test('영문은 대소문자를 가리지 않는다', () async {
      final viewModel = viewModelWith(
        StubStockRepository(byQuery: {'naver': [naver]}),
      );

      viewModel.onQueryChanged('naver');
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final row = viewModel.rows.single;
      expect(row.highlightStart, 0);
      expect(row.highlightEnd, 5);
    });

    test('종목명에 검색어가 없으면 강조하지 않는다', () async {
      final viewModel = viewModelWith(
        StubStockRepository(byQuery: {'005930': [samsung]}),
      );

      viewModel.onQueryChanged('005930');
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(viewModel.rows.single.hasHighlight, isFalse);
    });
  });

  group('결과 없음', () {
    test('ready 이면서 행이 비면 결과 없음이다', () async {
      final viewModel = viewModelWith(StubStockRepository());

      viewModel.onQueryChanged('없는종목');
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(viewModel.state, LoadState.ready);
      expect(viewModel.rows, isEmpty);
      expect(viewModel.query, '없는종목'); // 안내 문구에 넣을 검색어가 남아 있다
    });

    test('짧은 검색어는 문구에 그대로 넣는다', () {
      final viewModel = viewModelWith(StubStockRepository());

      viewModel.onQueryChanged('  삼성전자  ');

      expect(viewModel.queryLabel, '삼성전자');
    });

    test('긴 검색어는 20자에서 자른다', () {
      final viewModel = viewModelWith(StubStockRepository());

      viewModel.onQueryChanged('가나다라마바사아자차카타파하가나다라마바사아자차');

      // 자르지 않으면 뒤 문장이 화면 밖으로 밀린다.
      expect(viewModel.queryLabel, '가나다라마바사아자차카타파하가나다라마바…');
    });
  });

  group('관심 등록', () {
    test('토글하면 store 에 반영되고 등록 여부를 돌려준다', () async {
      final viewModel = viewModelWith(
        StubStockRepository(byQuery: {'삼성': [samsung]}),
      );
      viewModel.onQueryChanged('삼성');
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(viewModel.toggleFavorite('005930'), isTrue);
      expect(favorites.contains('005930'), isTrue);
      expect(viewModel.rows.single.isFavorite, isTrue);

      expect(viewModel.toggleFavorite('005930'), isFalse);
      expect(viewModel.rows.single.isFavorite, isFalse);
    });

    test('검색 직후에도 이미 등록된 종목은 켜진 상태로 나온다', () async {
      favorites.toggle(samsung);
      final viewModel = viewModelWith(
        StubStockRepository(byQuery: {'삼성': [samsung, samsungElec]}),
      );

      viewModel.onQueryChanged('삼성');
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(viewModel.rows.map((r) => r.isFavorite), [true, false]);
    });

    test('다른 화면에서 관심이 바뀌면 검색 결과도 따라 바뀐다', () async {
      final viewModel = viewModelWith(
        StubStockRepository(byQuery: {'삼성': [samsung]}),
      );
      viewModel.onQueryChanged('삼성');
      await Future<void>.delayed(const Duration(milliseconds: 30));

      favorites.toggle(samsung); // 관심 화면에서 등록한 상황

      expect(viewModel.rows.single.isFavorite, isTrue);
    });
  });

  group('실패', () {
    test('failed 와 문구를 남긴다', () async {
      final viewModel = viewModelWith(
        StubStockRepository(error: Exception('network')),
      );

      viewModel.onQueryChanged('삼성');
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(viewModel.state, LoadState.failed);
      expect(viewModel.errorMessage, '검색에 실패했습니다');
    });
  });

  group('입력이 바뀌는 동안 도착한 응답', () {
    // 옛 응답이 "입력이 바뀐 뒤 ~ 다음 디바운스가 끝나기 전" 창에 도착하는 경우다.
    // 이 창에서는 아직 새 요청이 나가지 않아 요청 번호가 그대로이므로,
    // 입력이 바뀐 순간에 번호를 올리지 않으면 옛 결과가 그대로 화면에 붙는다.
    test('디바운스가 끝나기 전에 도착한 옛 응답을 버린다', () async {
      final repository = StubStockRepository(
        byQuery: {
          '삼성': [samsung],
          '삼성전기': [samsungElec],
        },
        delays: {
          '삼성': const Duration(milliseconds: 30),
          '삼성전기': const Duration(milliseconds: 200),
        },
      );
      final viewModel = viewModelWith(
        repository,
        debounce: const Duration(milliseconds: 50),
      );

      viewModel.onQueryChanged('삼성'); // 50ms 요청 → 80ms 응답
      await Future<void>.delayed(const Duration(milliseconds: 60));
      viewModel.onQueryChanged('삼성전기'); // 110ms 요청 → 310ms 응답

      // 90ms — '삼성' 응답은 도착했고 '삼성전기' 요청은 아직 나가지도 않았다.
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(
        viewModel.rows,
        isEmpty,
        reason: '옛 검색어의 결과가 새 입력 아래에 남았다',
      );

      await Future<void>.delayed(const Duration(milliseconds: 240));
      expect(viewModel.rows.single.name, '삼성전기');
    });
  });
}
