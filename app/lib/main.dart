import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';

import 'data/repository/fake_stock_repository.dart';
import 'data/repository/naver_stock_repository.dart';
import 'data/repository/stock_repository.dart';
import 'state/favorites_store.dart';
import 'state/preferences.dart';
import 'ui/common/debug_log.dart';
import 'ui/search/search_view_model.dart';
import 'ui/watchlist/watchlist_view_model.dart';

/// 개발용 목업 전환. **기본값은 실제 endpoint 조회**다.
///
/// ```bash
/// flutter run --dart-define=USE_FAKE=true
/// ```
const bool useFake = bool.fromEnvironment('USE_FAKE');

Future<void> main() async {
  // 저장된 관심 목록 · 정렬 기준 · 최근 검색어를 첫 프레임 전에 읽어 둔다.
  // 늦게 읽으면 빈 목록이 한 번 그려졌다가 바뀌어 깜빡인다.
  WidgetsFlutterBinding.ensureInitialized();

  // 저장은 선택 항목이다. 플랫폼 채널이 실패해도 앱은 떠야 하므로 삼키고
  // 저장 없이 시작한다 — 여기서 던지면 선택 기능 하나가 전체 기동을 막는다.
  Preferences? preferences;
  try {
    preferences = await Preferences.load();
  } on Object catch (error) {
    logSwallowed('저장소 초기화', error);
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<StockRepository>(create: (_) => createStockRepository()),
        // 관심 상태 단일 원천 — 세 화면이 이 객체 하나를 본다.
        ChangeNotifierProvider<FavoritesStore>(
          create: (_) => FavoritesStore(preferences: preferences),
        ),
        ChangeNotifierProvider<WatchlistViewModel>(
          create: (BuildContext context) => WatchlistViewModel(
            repository: context.read<StockRepository>(),
            favorites: context.read<FavoritesStore>(),
            preferences: preferences,
          ),
        ),
        ChangeNotifierProvider<SearchViewModel>(
          create: (BuildContext context) => SearchViewModel(
            repository: context.read<StockRepository>(),
            favorites: context.read<FavoritesStore>(),
            preferences: preferences,
          ),
        ),
      ],
      child: const EdencrewAssignmentApp(),
    ),
  );
}

/// 구현체 이름이 등장하는 곳은 여기 하나다.
StockRepository createStockRepository() {
  if (!useFake) return NaverStockRepository();
  return FakeStockRepository(
    // `data` 는 flutter 를 import 하지 않으므로 asset 접근을 여기서 주입한다.
    loadAsset: (String path) async =>
        (await rootBundle.load(path)).buffer.asUint8List(),
  );
}
