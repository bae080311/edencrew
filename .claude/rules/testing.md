# 테스트

로직을 추가했으면 읽는다. PR 과 `main` 푸시에서는 CI(`.github/workflows/ci.yml`)가 `flutter analyze` 와 `flutter test` 를 자동으로 돌린다 — 로컬에서 통과시키고 올린다.

## 테스트

**로직을 추가하면 같은 커밋에 테스트를 넣는다.** 패키지는 `flutter_test` 만 쓴다 — golden 툴킷 · mock 라이브러리는 추가하지 않는다.

| 대상 | 파일 | 무엇을 |
| --- | --- | --- |
| `core/format.dart` | `format_test.dart` | 0 · 음수 · 보합, 축약 경계(999 / 1,000 / 1조), `MM.DD` |
| `SiseDayParser` | `sise_day_parser_test.dart` | mock HTML 고정 입력 — **EUC-KR 디코딩**, 컬럼 순서, `lastPage` |
| `FavoritesStore` | `favorites_store_test.dart` | 토글 · 중복 등록 · 순서 |
| ViewModel | `<화면>_view_model_test.dart` | `FakeStockRepository` 로 `LoadState` 전이, 기간 탭 latest-wins, **페이지 캐시가 요청 수를 줄이는지 호출 횟수로 검증** |
| 화면 | `layout_test.dart` | 기기 3종 + `textScaler` 1.3 에서 오버플로 없음 |

- View 자체는 단위 테스트 대신 레이아웃 테스트로 덮는다. 위젯 상호작용 테스트는 필수가 아니다.
- 페이지 캐시 검증은 평가 항목("필요한 만큼만, 재사용")을 **테스트로 증명**하는 자리다. `FakeStockRepository` 에 호출 카운터를 두고 1M → 3M 전환 때 1~6페이지를 다시 안 받는지 센다.
- 레이아웃 테스트는 오버플로만 본다. 픽셀 비교(골든 이미지)는 하지 않는다.

```dart
// test/layout_test.dart — 화면이 생기는 Phase 2 부터 채운다
Future<void> expectNoOverflow(WidgetTester tester, Widget app) async {
  for (final size in const [Size(375, 667), Size(393, 852), Size(430, 932)]) {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: '$size 오버플로');
  }
}
```
