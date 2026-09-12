import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';

import 'data/repository/fake_stock_repository.dart';
import 'data/repository/naver_stock_repository.dart';
import 'data/repository/stock_repository.dart';
import 'state/favorites_store.dart';

/// 개발용 목업 전환. **기본값은 실제 endpoint 조회**다.
///
/// ```bash
/// flutter run --dart-define=USE_FAKE=true
/// ```
const bool useFake = bool.fromEnvironment('USE_FAKE');

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<StockRepository>(create: (_) => createStockRepository()),
        // 관심 상태 단일 원천 — 세 화면이 이 객체 하나를 본다.
        ChangeNotifierProvider<FavoritesStore>(create: (_) => FavoritesStore()),
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
