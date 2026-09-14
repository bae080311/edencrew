# 아키텍처 결정 기록

이 문서는 **결정과 그 이유**를 남깁니다. 판단이 바뀐 항목은 지우지 않고 [변경 이력](#변경-이력)에 바꾼 이유를 덧붙입니다.

**고정** 은 바꾸면 거의 모든 파일이 움직이는 것, **현재 선택** 은 근거가 생기면 구현 중에 바꾸는 것입니다. 화면 단위 구현 판단은 [`README.md`](../README.md) 에 있습니다.

---

## 레이어 구조

```
lib/
├── main.dart          # DI 조립(MultiProvider)만. 화면 코드 없음
├── theme/             # 스타터가 제공한 디자인 토큰 (Figma 변수 1:1)
├── core/              # format.dart(포맷 단일 지점) · debug_log.dart
├── data/
│   ├── dto/           # Naver 응답 1:1 매핑
│   ├── source/        # NaverApi(HTTP), SiseDayParser(HTML)
│   ├── model/         # 앱 모델 (순수 Dart)
│   └── repository/    # StockRepository(추상) + Naver/Fake 구현
├── state/             # 화면 간 공유 상태 (FavoritesStore)
└── ui/
    ├── common/        # 두 곳 이상에서 쓰이는 위젯
    ├── app_shell.dart # 하단 탭 바
    ├── watchlist/     # <기능>_view / _view_model / _ui_model
    ├── search/
    └── detail/
```

데이터는 한 방향으로만 흐릅니다.

```
Naver 응답 ──parse──▶ DTO ──▶ (앱 모델) ──ViewModel──▶ UI 모델 ──▶ View
```

---

## 고정 결정

### 1. 의존 방향은 단방향

**선택** — `ui` 는 `state` / 추상 `StockRepository` / `data/model` / `core` / `theme` 만 참조합니다. `ui` 에서 `data/dto`, `data/source`, 구체 repository 를 import 하지 않습니다. 구현체 이름(`NaverStockRepository`, `FakeStockRepository`)은 `main.dart` 에만 등장합니다. `data` 는 `package:flutter/*` 를 import 하지 않습니다.

**이유** — 화면이 응답 형식을 알면 endpoint 가 바뀔 때 화면까지 고쳐야 합니다. `data` 를 순수 Dart 로 유지하면 파서와 계산을 위젯 없이 테스트할 수 있고, 실제 구현과 목업 구현을 바꿔 끼울 수 있습니다.

### 2. 관심 상태는 단일 원천

**선택** — `state/favorites_store.dart`(`ChangeNotifier`) 하나를 앱 최상단에 두고 세 화면이 같은 객체를 봅니다. 화면마다 관심 목록 사본을 두지 않습니다.

**이유** — 과제가 요구하는 3화면 동기화(관심 · 검색 · 상세의 별 아이콘, 검색에서 등록한 종목이 관심 목록에 반영)를 "같은 객체를 본다"로 해결합니다. 화면별 사본을 두면 동기화 코드를 세 곳에 짜야 하고, 한 곳을 빠뜨리면 어긋납니다.

### 3. 포맷은 한 곳에서만

**선택** — 천 단위 구분, 등락 표기(`-400 (-0.22%)`), 축약(`29,113천`, `1,063조`), `MM.DD` 를 `core/format.dart` 에 모읍니다. 화면 코드에서 직접 포맷하지 않습니다. `intl` 은 쓰지 않습니다.

**이유** — 같은 숫자가 화면마다 다르게 보이는 사고를 원천 차단합니다. 축약 단위(천 · 조)는 한국식 표기라 `intl` 을 쓰더라도 결국 직접 써야 해서 의존성을 늘릴 이유가 없습니다.

### 4. 캐시는 repository 안에 숨깁니다

**선택** — 일별 시세 페이지 캐시와 종목 메타 캐시를 `NaverStockRepository` 내부에 둡니다. ViewModel 은 캐시의 존재를 모르고 "이 기간 데이터를 달라"고만 요청합니다.

**이유** — 과제가 "필요한 만큼만 받고 이미 받은 페이지는 재사용"을 명시적으로 평가합니다. 캐시가 ViewModel 로 새면 상세 화면마다 같은 로직을 반복하게 되고, 기간 탭 4개가 각자 캐시를 갖는 상태가 됩니다. 요청 최적화는 데이터 계층의 책임입니다.

### 5. 목업 전환 스위치

**선택** — `StockRepository` 추상 클래스 + `FakeStockRepository`. Fake 는 `assets/mock/` 에 저장한 실제 응답을 **실제 구현과 같은 파서**로 읽습니다. `--dart-define=USE_FAKE=true` 분기는 `main.dart` 한 곳에만 있습니다.

```bash
flutter run --dart-define=USE_FAKE=true
```

**이유** — Naver endpoint 는 호출이 잦으면 느려지거나 막힙니다. 목업이 처음부터 있으면 네트워크 상태와 무관하게 파싱 · UI 작업을 진행할 수 있습니다. 파서를 공유해야 Fake 가 실제 응답과 어긋나지 않습니다 — 목업용 파싱 코드를 따로 두면 목업에서만 동작하는 화면이 됩니다.

---

## 현재 선택

### 상태관리 — `provider` + `ChangeNotifier`

화면별 ViewModel 은 라우트에서 `ChangeNotifierProvider` 로 만들고, repository 와 store 는 `context.read` 로 주입합니다.

화면 3개 규모에서 `ChangeNotifier` 로 충분하고, 상태관리와 DI 를 같은 도구로 해결할 수 있습니다. Riverpod 은 테스트와 스코프 관리가 깔끔하지만 이 규모에서 얻는 이득보다 개념(Provider · Notifier · ref) 학습 비용이 크다고 판단했습니다. 별도 DI 컨테이너(`get_it` 등)는 두지 않았습니다 — 주입 지점이 `main.dart` 하나여서 Provider 로 충분합니다.

### 화면 상태 — enum + 보조 플래그

```dart
enum LoadState { initial, loading, ready, failed }
```

- `errorMessage` 는 `failed` 에서만 의미를 갖습니다.
- `isRefreshing` 은 `ready` 상태에서 기존 목록을 보여주며 갱신 중일 때 씁니다.
- **빈 상태는 별도 플래그를 두지 않고** `ready && rows.isEmpty` 로 파생시킵니다.
- 행 단위 스켈레톤은 화면 상태가 아니라 행 모델의 `isSkeleton` 입니다.

플래그를 여러 개 두면 `isLoading && isEmpty && errorMessage != null` 처럼 해석이 불가능한 조합이 생깁니다. 반대로 화면 전체를 하나의 `sealed class` union 으로 만들면 "목록은 보이는데 일부 행만 스켈레톤" 같은 실제 상태를 표현하기 어렵습니다. 화면 단위 상태는 enum 으로, 행 단위 상태는 행 모델로 분리한 이유입니다.

### UI 모델 — 타입이 아니라 책임으로 제한

규칙은 하나입니다. **View 는 비즈니스 계산을 하지 않습니다.** 정렬 · 포맷 · 등락 계산 · 하이라이트 구간 계산은 ViewModel 에서 끝내고, View 는 받은 값을 배치합니다.

타입은 제한하지 않습니다. 차트 좌표나 선택 인덱스처럼 UI 자체가 숫자를 필요로 하면 `double`/`int` 를 그대로 담습니다. 다만 `Color`/`TextStyle`/`Widget` 은 담지 않습니다 — 토큰 접근에 `BuildContext` 가 필요해서 UI 모델에서 만들 수 없고, 의미(`PriceTone { up, down, flat }`)로 넘기고 View 에서 `context.colors` 로 매핑하는 편이 테마와의 결합도 낮습니다.

### 모델 겹수 — 필요한 곳에만

DTO 는 endpoint 경계마다 둡니다. 응답 필드명(`nv`, `pcv`, `aq`)이 앱 어휘와 전혀 다르고, DTO 가 있어야 응답 형식 변화가 한 파일에서 멈춥니다.

앱 모델 겹은 아래 중 하나라도 해당할 때만 둡니다.

1. 여러 소스를 합칩니다 — 메타 + 시세 → `Stock`
2. 계산이 붙습니다 — 등락액 `nv - pcv`, 등락률 `(nv - pcv) / pcv`, 시가총액 `nv × countOfListedStock` → `Quote`
3. 여러 화면이 공유합니다

셋 다 아니고 DTO → 모델이 필드 복사뿐이면 한 겹으로 합칩니다. 겹수를 맞추려고 의미 없는 변환 코드를 늘리지 않습니다. 어떤 데이터를 어떻게 처리했는지는 변경 이력에 기록합니다.

### 중복 요청 방지 — 액션 단위로 다르게

- **새로고침** 처럼 같은 요청의 반복은 진행 중이면 무시합니다.
- **기간 탭 전환** 은 latest-wins 입니다. 응답이 도착했을 때 `if (period != _selectedPeriod) return;` 로 오래된 응답을 버립니다. 하나의 플래그로 전부 막으면 `1개월 → 3개월` 을 빠르게 눌렀을 때 나중 의도가 무시됩니다.
- **검색** 은 디바운스 + latest-wins 입니다.

### 종목 식별자 — canonical id

앱 내부는 `domestic:{6자리}` 로 다루고, Naver 요청 직전에만 symbol 로 바꿉니다. 자동완성 응답에는 지수 · 해외 종목 · IPO 가 섞여 오므로 경계에서 국내 · 6자리만 통과시켜 내부를 단일 규칙으로 유지합니다.

### 에러 처리 — 예외를 그대로 던집니다

`data` 계층은 예외를 그대로 throw 하고 ViewModel 이 `try/catch` 로 받아 `failed` + `errorMessage` 로 바꿉니다. `Result` 래퍼 타입은 만들지 않았습니다 — 소비 지점이 ViewModel 한 곳뿐이라 래퍼가 주는 이득이 없습니다.

삼킨 예외는 `core/debug_log.dart` 에 모아 스택과 함께 남기고, `main()` 에서 `FlutterError.onError` 와 `PlatformDispatcher.instance.onError` 를 걸어 아무도 받지 않는 예외까지 같은 형식으로 남깁니다. 전부 `assert` 안이라 release 빌드에서는 호출 자체가 빠집니다.

### 라우팅 · 탭

`Navigator.push(MaterialPageRoute)` 를 씁니다. 화면 3개에 딥링크 요구가 없어 `go_router` 는 과합니다. 하단 탭은 `IndexedStack` 으로 두 화면을 유지해 탭을 옮겨도 검색어와 스크롤 위치가 남게 합니다.

### 공통 컴포넌트 승격 기준

**두 번째 사용처가 실제로 생겼을 때** `ui/common/` 으로 옮깁니다. 미리 공통화하면 쓰이지 않는 파라미터만 늘어납니다.

### 테스트 범위

`core/format.dart` 와 일별 시세 파서에 유닛 테스트를 둡니다. 깨지면 화면 전체가 틀리고, 위젯 없이 검증할 수 있는 지점입니다. 화면은 `layout_test.dart` 의 오버플로 검증으로 덮고, 나머지는 `flutter analyze` 로 커버합니다.

### 영속성

관심 목록 · 정렬 기준 · 최근 검색어를 `shared_preferences` 로 저장합니다(2026-09-14 구현). 읽기 · 쓰기는 `state/preferences.dart` 한 곳에 모으고, `FavoritesStore` 와 두 ViewModel 에 **선택 인자**로 넘깁니다 — 화면 코드는 저장 방식을 모르고, 인자를 주지 않는 테스트는 저장 없이 그대로 돕니다. 저장값이 깨져 있으면 빈 값으로 떨어집니다.

---

## 변경 이력

> 형식 — **날짜 · 항목** — 무엇을 어떻게 바꿨는지. *왜* 그랬는지.

- **2026-09-11 · 모델 겹수** — `Stock` · `Quote` · `DailyPrice` 세 겹을 유지했습니다. 각각 기준을 충족하기 때문입니다 — `Stock` 은 자동완성과 메타 두 소스를 합치고, `Quote` 는 등락 · 시가총액 계산이 붙고, `DailyPrice` 는 차트와 일별 시세 표가 함께 씁니다. 필드 복사뿐인 겹은 만들지 않았습니다.

- **2026-09-11 · 의미 enum 위치** — `PriceTone` · `ChartPeriod` 를 `data/model/` 에 두었습니다. 둘 다 `ui` 와 `data` 양쪽이 쓰는데, `ui` 에 두면 `data` 가 `ui` 를 참조해 의존 방향이 뒤집힙니다. 표시 문자열은 넣지 않아 `data` 의 순수성을 해치지 않습니다.

- **2026-09-11 · 일별 시세 등락 (계획을 뒤집었습니다)** — 인접 행 종가 차이로 계산하려던 것을 HTML 의 방향 아이콘을 읽는 쪽으로 바꿨습니다. 실제 응답을 받아보니 전일비 칸마다 `<em class="bu_p bu_pup/bu_pdn/bu_pn">` 로 방향이 명시되어 있었습니다. 인접 행 차이는 페이지의 가장 오래된 행에서 값이 비는데, 아이콘을 읽으면 모든 행이 채워집니다. 보합(`bu_pn`)은 전일비가 0 이라 부호를 0 으로 두어도 값이 같습니다.

- **2026-09-12 · 매퍼 계층 신설** — DTO 안에 있던 모델 변환을 `data/mapper/` 로 옮겼습니다. DTO 가 모델을 import 하면 **응답 형식이 바뀔 때도, 앱 모델이 바뀔 때도** 같은 파일을 엽니다. 변환을 따로 두면 DTO 는 응답 구조만, 모델은 값과 계산만 책임집니다. 매퍼는 DTO 하나당 하나로 둡니다.

- **2026-09-12 · 파일 분리** — 한 파일에 최상위 타입 둘을 담지 않기로 했습니다. `WatchlistSort`(정렬 기준)와 `WatchlistRowUi`(행 데이터), `DailyPriceDto` 와 `SiseDayPageDto` 는 서로 다른 이유로 바뀝니다. `main.dart` 의 앱 위젯도 `app.dart` 로 뺐습니다 — 조립과 화면은 다른 일입니다.

- **2026-09-12 · 타이포그래피 토큰** — 스타터가 비워둔 글자 크기 · 행간을 `AppTypography` 의 `TextStyle` 상수 5개로 채웠습니다. Figma Variables 에는 없지만 **이름 붙은 텍스트 스타일**(`display/price` · `title` · `body` · `label` · `caption`)로는 정의되어 있었습니다. 화면마다 크기를 적으면 같은 값이 흩어지고 시안 대조가 불가능해집니다. 값은 그대로 옮겼고 새 스케일을 만들지 않았습니다. 색은 담지 않아 `BuildContext` 없이 `const` 로 둘 수 있습니다.

- **2026-09-12 · 시안 원시값 (판단을 뒤집었습니다)** — 대응표가 깨지는 것이 싫어 위젯 안 `const` 로 두었던 간격 · 아이콘 크기를 `AppDimens` 로 올렸습니다. 같은 값이 화면마다 흩어져 "간격은 토큰으로만" 규칙이 무의미해졌기 때문입니다. 대응표가 깨지는 문제는 Figma 변수에서 온 표와 시안 레이어에서 읽은 표를 갈라 적어 해결했습니다. **한 위젯의 상자 크기**(스켈레톤 막대, 차트 높이, 표의 날짜 칸)만 위젯에 남깁니다.

- **2026-09-14 · 영속성** — 계획대로 `shared_preferences` 를 도입하되, 저장 대상이 관심 목록 하나가 아니라 정렬 기준 · 최근 검색어까지 셋이 되어 `FavoritesStore` 내부가 아닌 `state/preferences.dart` 로 뺐습니다. 정렬 기준과 검색어는 관심 목록의 관심사가 아닙니다. 셋을 한 스토어에 밀어 넣으면 `FavoritesStore` 를 여는 이유가 둘 이상이 됩니다.

- **2026-09-14 · 상세 화면의 실패 신호** — 첫 조회 실패와 기간 전환 실패가 공유하던 `errorMessage` 를 `errorMessage`(non-null)와 `periodError`(nullable) 둘로 갈랐습니다. 전자는 화면 전체를 실패로 덮고 후자는 이미 그린 구간을 두고 한 줄만 알려야 하는데, 같은 값을 보면 구분할 수 없었습니다. 회귀 테스트로 고정했습니다.

- **2026-09-14 · `debug_log` 위치** — `ui/common/` 에 두었던 것을 `core/` 로 내렸습니다. `state/preferences.dart` 가 이 파일을 쓰면서 **`state` → `ui` 역방향 import** 가 생겼기 때문입니다. 로그는 화면의 관심사가 아니라 어느 레이어에서나 부르는 공통 도구이므로 처음부터 `core` 가 맞았습니다.

- **2026-09-14 · 일별 시세 표 렌더링** — 본문을 `CustomScrollView` 로 바꾸고 표를 `SliverList.builder` 로 뺐습니다. 1년(245행)에서 화면이 멈춰 `tool/measure_period.dart` 로 재 보니 네트워크(25페이지 0.24초)도 파싱(장당 1.7ms)도 아니고 위젯을 한 프레임에 전부 세우는 쪽이 병목이었습니다. 선택 항목이던 무한 스크롤도 이것으로 해결됩니다.
