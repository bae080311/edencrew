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
import 'package:edencrew_assignment_starter/ui/watchlist/watchlist_row.dart';
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

Quote quoteOf(
  String symbol, {
  required int price,
  required int previousClose,
}) => Quote(
  symbol: symbol,
  price: price,
  previousClose: previousClose,
  open: price,
  high: price,
  low: price,
  volume: 0,
  listedShares: 1000,
);

/// 상승 · 하락 · 보합이 섞인 일별 시세. 캔들 색과 등락 부호를 모두 지난다.
List<DailyPrice> dailyPricesOf(int count) => <DailyPrice>[
  for (int i = 0; i < count; i++)
    DailyPrice(
      date:
          '2026${(i % 12 + 1).toString().padLeft(2, '0')}'
          '${(i % 28 + 1).toString().padLeft(2, '0')}',
      close: 170000 + (i % 7) * 1500,
      diff: (i % 3 - 1) * 1200,
      open: 170000 + (i % 5) * 900,
      high: 176000 + (i % 4) * 800,
      low: 168000 - (i % 3) * 500,
      volume: 29113466 + i * 1000,
    ),
];

class StubStockRepository implements StockRepository {
  StubStockRepository({
    this.quotes = const <String, Quote>{},
    this.searchResults = const <Stock>[],
    this.dailyPrices = const <DailyPrice>[],
    this.error,
  });

  final Map<String, Quote> quotes;
  final List<Stock> searchResults;
  final List<DailyPrice> dailyPrices;
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
  Future<Stock> fetchStockMeta(String symbol) async {
    if (error != null) throw error!;
    return searchResults.firstWhere(
      (Stock stock) => stock.symbol == symbol,
      orElse: () => samsung,
    );
  }

  @override
  Future<List<DailyPrice>> fetchDailyPrices(
    String symbol,
    ChartPeriod period,
  ) async {
    if (error != null) throw error!;
    return dailyPrices.take(period.tradingDays).toList();
  }
}

/// 상세 화면까지 값이 흐르는 저장소. 축약 표기를 지나도록 거래량 · 상장주식수를 실제 규모로 둔다.
StubStockRepository detailRepository(List<DailyPrice> prices) =>
    StubStockRepository(
      searchResults: const <Stock>[longName],
      quotes: <String, Quote>{
        '373220': const Quote(
          symbol: '373220',
          price: 195400,
          previousClose: 194200,
          open: 194500,
          high: 196800,
          low: 193900,
          volume: 29113466,
          listedShares: 5969782550,
        ),
      },
      dailyPrices: prices,
    );

/// 검색 결과 첫 행을 눌러 상세 화면을 연다. 별 아이콘은 오른쪽 끝이라 행 가운데를 누른다.
Future<void> openDetail(WidgetTester tester, {required String query}) async {
  await openSearch(tester, query: query);
  await tester.tap(find.byType(SearchRow).first);
  await tester.pumpAndSettle();
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
        create: (BuildContext context) =>
            WatchlistViewModel(repository: repository, favorites: store),
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
        repository: StubStockRepository(searchResults: const <Stock>[samsung]),
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

  testWidgets('종목상세 화면이 넘치지 않는다', (WidgetTester tester) async {
    await expectNoOverflow(
      tester,
      (double textScale) => appWith(
        repository: detailRepository(dailyPricesOf(60)),
        favorites: const <Stock>[],
        textScale: textScale,
      ),
      after: (WidgetTester tester) => openDetail(tester, query: 'LG'),
    );
  });

  testWidgets('1년 탭으로 바꿔도 넘치지 않는다', (WidgetTester tester) async {
    await expectNoOverflow(
      tester,
      (double textScale) => appWith(
        // 1페이지 = 10거래일이라 1년은 245행까지 쌓인다.
        repository: detailRepository(dailyPricesOf(245)),
        favorites: const <Stock>[],
        textScale: textScale,
      ),
      after: (WidgetTester tester) async {
        await openDetail(tester, query: 'LG');
        await tester.tap(find.text('1년'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('검색 결과 행을 누르면 종목상세로 간다', (WidgetTester tester) async {
    await tester.pumpWidget(
      appWith(
        repository: detailRepository(dailyPricesOf(20)),
        favorites: const <Stock>[],
        textScale: 1,
      ),
    );
    await tester.pumpAndSettle();
    await openDetail(tester, query: 'LG');

    expect(find.text('일별 시세'), findsOneWidget);
    expect(find.text('373220 · 코스닥'), findsOneWidget);
  });

  testWidgets('상세에서 관심을 해제하면 목록에서도 빠진다', (WidgetTester tester) async {
    await tester.pumpWidget(
      appWith(
        repository: detailRepository(dailyPricesOf(20)),
        favorites: const <Stock>[longName],
        textScale: 1,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(WatchlistRow).first);
    await tester.pumpAndSettle();

    // 상세 헤더의 별. 화면에 별 아이콘은 이것 하나다.
    await tester.tap(find.byType(AppIcon).at(1));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppIcon).first);
    await tester.pumpAndSettle();

    // 세 화면이 FavoritesStore 하나를 본다는 증거다.
    expect(find.text('관심 종목이 없습니다'), findsOneWidget);
  });

  testWidgets('관심 행을 왼쪽으로 밀면 목록에서 빠진다', (WidgetTester tester) async {
    await tester.pumpWidget(
      appWith(
        repository: detailRepository(dailyPricesOf(20)),
        favorites: const <Stock>[longName],
        textScale: 1,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(WatchlistRow), findsOneWidget);

    await tester.drag(find.byType(WatchlistRow).first, const Offset(-500, 0));
    await tester.pumpAndSettle();

    // 마지막 종목을 뺐으니 빈 상태가 된다 — 스토어까지 반영됐다는 뜻이다.
    expect(find.byType(WatchlistRow), findsNothing);
    expect(find.text('관심 종목이 없습니다'), findsOneWidget);
  });
}
