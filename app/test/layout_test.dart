import 'package:edencrew_assignment_starter/data/model/chart_period.dart';
import 'package:edencrew_assignment_starter/data/model/daily_price.dart';
import 'package:edencrew_assignment_starter/data/model/quote.dart';
import 'package:edencrew_assignment_starter/data/model/stock.dart';
import 'package:edencrew_assignment_starter/data/repository/stock_repository.dart';
import 'package:edencrew_assignment_starter/state/favorites_store.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:edencrew_assignment_starter/ui/app_shell.dart';
import 'package:edencrew_assignment_starter/ui/common/app_icon.dart';
import 'package:edencrew_assignment_starter/ui/search/search_row.dart';
import 'package:edencrew_assignment_starter/ui/search/search_view_model.dart';
import 'package:edencrew_assignment_starter/ui/watchlist/watchlist_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// 확인 대상 기기. 태블릿 · 가로 모드는 대상이 아니다.
const List<Size> devices = <Size>[
  Size(375, 667),
  Size(393, 852),
  Size(430, 932),
];

const Stock samsung = Stock(
  symbol: '005930',
  name: '삼성전자',
  exchangeName: '코스피',
);

/// 오버플로가 잘 나는 조건이라 일부러 긴 이름을 섞는다.
const Stock longName = Stock(
  symbol: '373220',
  name: 'LG에너지솔루션우선주삼성바이오로직스',
  exchangeName: '코스닥',
);

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

class StubStockRepository implements StockRepository {
  StubStockRepository({
    this.quotes = const <String, Quote>{},
    this.searchResults = const <Stock>[],
    this.error,
  });

  final Map<String, Quote> quotes;
  final List<Stock> searchResults;
  final Object? error;

  @override
  Future<Map<String, Quote>> fetchQuotes(List<String> symbols) async {
    if (error != null) throw error!;
    return <String, Quote>{
      for (final String symbol in symbols)
        if (quotes.containsKey(symbol)) symbol: quotes[symbol]!,
    };
  }

  @override
  Future<List<Stock>> searchStocks(String query) async => searchResults;

  @override
  Future<Stock> fetchStockMeta(String symbol) => throw UnimplementedError();

  @override
  Future<List<DailyPrice>> fetchDailyPrices(
    String symbol,
    ChartPeriod period,
  ) => throw UnimplementedError();
}

Widget appWith({
  required StockRepository repository,
  required List<Stock> favorites,
  required double textScale,
}) {
  final FavoritesStore store = FavoritesStore();
  for (final Stock stock in favorites) {
    store.toggle(stock);
  }

  return MultiProvider(
    providers: [
      Provider<StockRepository>.value(value: repository),
      ChangeNotifierProvider<FavoritesStore>.value(value: store),
      ChangeNotifierProvider<WatchlistViewModel>(
        create: (BuildContext context) => WatchlistViewModel(
          repository: repository,
          favorites: store,
        ),
      ),
      ChangeNotifierProvider<SearchViewModel>(
        // 디바운스를 없애 입력 직후 결과를 본다. 디바운스 자체는 ViewModel 테스트가 덮는다.
        create: (BuildContext context) => SearchViewModel(
          repository: repository,
          favorites: store,
          debounce: Duration.zero,
        ),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      // MaterialApp 안쪽에서 덮어야 앱이 만든 MediaQuery 를 이긴다.
      home: Builder(
        builder: (BuildContext context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: const AppShell(),
        ),
      ),
    ),
  );
}

/// 기기 3종 × 글자 배율에서 오버플로가 없는지 본다. 픽셀 비교는 하지 않는다.
Future<void> expectNoOverflow(
  WidgetTester tester,
  Widget Function(double textScale) build, {
  Future<void> Function(WidgetTester tester)? after,
}) async {
  for (final Size size in devices) {
    for (final double textScale in <double>[1, 1.3]) {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      // 앞 반복에서 열어둔 라우트가 남지 않도록 트리를 비우고 시작한다.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(build(textScale));
      await tester.pumpAndSettle();
      if (after != null) await after(tester);

      expect(tester.takeException(), isNull, reason: '$size · 배율 $textScale');
    }
  }
}

/// 검색 탭으로 옮기고, 검색어가 있으면 입력까지 한다.
Future<void> openSearch(WidgetTester tester, {String? query}) async {
  await tester.tap(find.text('검색'));
  await tester.pumpAndSettle();
  if (query == null) return;
  await tester.enterText(find.byType(TextField), query);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('관심 목록이 넘치지 않는다', (WidgetTester tester) async {
    final StubStockRepository repository = StubStockRepository(
      quotes: <String, Quote>{
        '005930': quoteOf('005930', price: 179700, previousClose: 180100),
        '373220': quoteOf('373220', price: 195400, previousClose: 195400),
      },
    );

    await expectNoOverflow(
      tester,
      (double textScale) => appWith(
        repository: repository,
        favorites: const <Stock>[samsung, longName],
        textScale: textScale,
      ),
    );
  });

  testWidgets('시세를 못 받은 행이 스켈레톤으로 떠도 넘치지 않는다', (WidgetTester tester) async {
    await expectNoOverflow(
      tester,
      (double textScale) => appWith(
        repository: StubStockRepository(),
        favorites: const <Stock>[samsung, longName],
        textScale: textScale,
      ),
    );
  });

  testWidgets('빈 상태가 넘치지 않는다', (WidgetTester tester) async {
    await expectNoOverflow(
      tester,
      (double textScale) => appWith(
        repository: StubStockRepository(),
        favorites: const <Stock>[],
        textScale: textScale,
      ),
    );
  });

  testWidgets('실패 상태가 넘치지 않는다', (WidgetTester tester) async {
    await expectNoOverflow(
      tester,
      (double textScale) => appWith(
        repository: StubStockRepository(error: Exception('네트워크')),
        favorites: const <Stock>[samsung],
        textScale: textScale,
      ),
    );
  });

  testWidgets('정렬 바텀시트가 넘치지 않는다', (WidgetTester tester) async {
    await expectNoOverflow(
      tester,
      (double textScale) => appWith(
        repository: StubStockRepository(),
        favorites: const <Stock>[samsung],
        textScale: textScale,
      ),
      after: (WidgetTester tester) async {
        await tester.tap(find.text('현재가순'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('탭 바로 검색 화면과 오간다', (WidgetTester tester) async {
    await tester.pumpWidget(
      appWith(
        repository: StubStockRepository(),
        favorites: const <Stock>[samsung],
        textScale: 1,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('관심'), findsWidgets);

    await tester.tap(find.text('검색'));
    await tester.pumpAndSettle();

    expect(find.text('종목을 검색해 보세요'), findsOneWidget);
  });

  testWidgets('검색에서 등록한 종목이 관심 목록에 나타난다', (WidgetTester tester) async {
    await tester.pumpWidget(
      appWith(
        repository: StubStockRepository(
          searchResults: const <Stock>[samsung],
        ),
        favorites: const <Stock>[],
        textScale: 1,
      ),
    );
    await tester.pumpAndSettle();
    await openSearch(tester, query: '삼성');

    await tester.tap(
      find.descendant(
        of: find.byType(SearchRow),
        matching: find.byType(AppIcon),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('관심'));
    await tester.pumpAndSettle();

    // 두 화면이 FavoritesStore 하나를 보고 있다는 증거다.
    expect(find.text('005930 · 코스피'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('검색 전 빈 상태가 넘치지 않는다', (WidgetTester tester) async {
    await expectNoOverflow(
      tester,
      (double textScale) => appWith(
        repository: StubStockRepository(),
        favorites: const <Stock>[],
        textScale: textScale,
      ),
      after: openSearch,
    );
  });

  testWidgets('검색 결과 목록이 넘치지 않는다', (WidgetTester tester) async {
    await expectNoOverflow(
      tester,
      (double textScale) => appWith(
        repository: StubStockRepository(
          searchResults: const <Stock>[samsung, longName],
        ),
        favorites: const <Stock>[],
        textScale: textScale,
      ),
      after: (WidgetTester tester) => openSearch(tester, query: '삼성'),
    );
  });

  testWidgets('긴 검색어의 결과 없음 문구가 넘치지 않는다', (WidgetTester tester) async {
    await expectNoOverflow(
      tester,
      (double textScale) => appWith(
        repository: StubStockRepository(),
        favorites: const <Stock>[],
        textScale: textScale,
      ),
      after: (WidgetTester tester) =>
          openSearch(tester, query: '삼성전자우선주와엘지에너지솔루션과에스케이하이닉스'),
    );
  });

  testWidgets('관심 등록 토스트가 넘치지 않는다', (WidgetTester tester) async {
    await expectNoOverflow(
      tester,
      (double textScale) => appWith(
        repository: StubStockRepository(
          searchResults: const <Stock>[samsung, longName],
        ),
        favorites: const <Stock>[],
        textScale: textScale,
      ),
      after: (WidgetTester tester) async {
        await openSearch(tester, query: '삼성');
        await tester.tap(
          find.descendant(
            of: find.byType(SearchRow).first,
            matching: find.byType(AppIcon),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('관심이 등록되었습니다'), findsOneWidget);

        // 다음 반복으로 넘어가기 전에 노출 시간과 퇴장 애니메이션을 흘려보낸다.
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
      },
    );
  });
}
