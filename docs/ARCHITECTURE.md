# 아키텍처 결정 기록

이 문서는 **결정과 그 이유**를 남긴다. 구현하면서 판단이 바뀐 항목은 지우지 않고 아래 [변경 이력](#변경-이력)에 바꾼 이유와 시점을 덧붙인다. 처음부터 완벽한 설계를 선언하는 문서가 아니라, 무엇을 왜 골랐고 왜 바꿨는지를 추적하는 문서다.

결정은 두 등급으로 나눈다.

- **고정** — 나중에 바꾸면 거의 모든 파일이 움직인다. 바꾸기 전에 반드시 다시 생각한다.
- **현재 선택** — 근거가 생기면 구현 중에 바꾼다. 바꾸면 변경 이력에 남긴다.

---

## 레이어 구조

```
lib/
├── main.dart          # DI 조립(MultiProvider)만. 화면 코드 없음
├── theme/             # 스타터가 제공한 디자인 토큰 (Figma 변수 1:1)
├── core/format.dart   # 숫자·날짜 포맷 단일 지점
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

데이터는 한 방향으로만 흐른다.

```
Naver 응답 ──parse──▶ DTO ──▶ (앱 모델) ──ViewModel──▶ UI 모델 ──▶ View
```

---

## 고정 결정

### 1. 의존 방향은 단방향

**선택** — `ui` → `state` / 추상 `StockRepository` / `data/model` / `core` / `theme` 만 참조한다. `ui` 에서 `data/dto`, `data/source`, 구체 repository 를 import 하지 않는다. 구현체 이름(`NaverStockRepository`, `FakeStockRepository`)은 `main.dart` 에만 등장한다. `data` 는 `package:flutter/*` 를 import 하지 않는다.

**이유** — 화면이 응답 형식을 알면 endpoint 가 바뀔 때 화면까지 고쳐야 한다. `data` 를 순수 Dart 로 유지하면 파서와 계산을 위젯 없이 테스트할 수 있고, 실제 구현과 목업 구현을 바꿔 끼울 수 있다.

### 2. 관심 상태는 단일 원천

**선택** — `state/favorites_store.dart` (`ChangeNotifier`) 하나를 앱 최상단에 두고 세 화면이 같은 객체를 본다. 화면마다 관심 목록 사본을 두지 않는다.

**이유** — 과제가 요구하는 3화면 동기화(관심 · 검색 · 상세의 별 아이콘, 검색에서 등록한 종목이 관심 목록에 반영)를 "같은 객체를 본다"로 해결한다. 화면별 사본을 두면 동기화 코드를 세 곳에 짜야 하고, 한 곳을 빠뜨리면 어긋난다.

### 3. 포맷은 한 곳에서만

**선택** — 천 단위 구분, 등락 표기(`-400 (-0.22%)`), 축약(`29,113천`, `1,063조`), `MM.DD` 를 `core/format.dart` 에 모은다. 화면 코드에서 직접 포맷하지 않는다. `intl` 은 쓰지 않는다.

**이유** — 같은 숫자가 화면마다 다르게 보이는 사고를 원천 차단한다. 축약 단위(천 · 조)는 한국식 표기라 `intl` 로도 결국 직접 써야 해서 의존성을 늘릴 이유가 없다.

### 4. 캐시는 repository 안에 숨긴다

**선택** — 일별 시세 페이지 캐시와 종목 메타 캐시를 `NaverStockRepository` 내부에 둔다. ViewModel 은 캐시의 존재를 모르고 "이 기간 데이터를 달라"고만 요청한다.

**이유** — 과제가 "필요한 만큼만 받고 이미 받은 페이지는 재사용" 을 명시적으로 평가한다. 캐시가 ViewModel 로 새면 상세 화면마다 같은 로직을 반복하게 되고, 기간 탭 4개가 각자 캐시를 갖는 상태가 된다. 요청 최적화는 데이터 계층의 책임이다.

### 5. 목업 전환 스위치

**선택** — `StockRepository` 추상 클래스 + `FakeStockRepository`. Fake 는 `assets/mock/` 에 저장한 실제 응답을 **실제 구현과 같은 파서**로 읽는다. `--dart-define=USE_FAKE=true` 분기는 `main.dart` 한 곳에만 있다.

```bash
flutter run --dart-define=USE_FAKE=true
```

**이유** — Naver endpoint 는 호출이 잦으면 느려지거나 막힌다. 목업이 처음부터 있으면 네트워크 상태와 무관하게 파싱·UI 작업을 진행할 수 있다. 파서를 공유해야 Fake 가 실제 응답과 어긋나지 않는다 — 목업용 파싱 코드를 따로 두면 목업에서만 동작하는 화면이 된다.

---

## 현재 선택

### 상태관리 — `provider` + `ChangeNotifier`

화면별 ViewModel 은 라우트에서 `ChangeNotifierProvider` 로 만들고, repository 와 store 는 `context.read` 로 주입한다.

화면 3개 규모에서 `ChangeNotifier` 로 충분하고, 상태관리와 DI 를 같은 도구로 해결할 수 있다. Riverpod 은 테스트와 스코프 관리가 깔끔하지만 이 규모에서 얻는 이득보다 개념(Provider · Notifier · ref) 학습 비용이 크다고 판단했다. 의존성 주입을 위해 별도 DI 컨테이너(`get_it` 등)를 두지 않았다 — 주입 지점이 `main.dart` 하나여서 Provider 로 충분하다.

### 화면 상태 — enum + 보조 플래그

```dart
enum LoadState { initial, loading, ready, failed }
```

- `errorMessage` 는 `failed` 에서만 의미를 갖는다.
- `isRefreshing` 은 `ready` 상태에서 기존 목록을 보여주며 갱신 중일 때 쓴다.
- **빈 상태는 별도 플래그를 두지 않고** `ready && rows.isEmpty` 로 파생시킨다.
- 행 단위 스켈레톤은 화면 상태가 아니라 행 모델의 `isSkeleton` 이다.

플래그를 여러 개 두면 `isLoading && isEmpty && errorMessage != null` 처럼 해석이 불가능한 조합이 생긴다. 반대로 화면 전체를 하나의 `sealed class` union 으로 만들면 "목록은 보이는데 일부 행만 스켈레톤" 같은 실제 상태를 표현하기 어렵다. 화면 단위 상태는 enum 으로, 행 단위 상태는 행 모델로 분리한 이유다.

### UI 모델 — 타입이 아니라 책임으로 제한

규칙은 하나다. **View 는 비즈니스 계산을 하지 않는다.** 정렬 · 포맷 · 등락 계산 · 하이라이트 구간 계산은 ViewModel 에서 끝내고, View 는 받은 값을 배치한다.

타입은 제한하지 않는다. 차트 좌표나 선택 인덱스처럼 UI 자체가 숫자를 필요로 하면 `double`/`int` 를 그대로 담는다. 다만 `Color`/`TextStyle`/`Widget` 은 담지 않는다 — 토큰 접근에 `BuildContext` 가 필요해서 UI 모델에서 만들 수 없고, 의미(`PriceTone { up, down, flat }`)로 넘기고 View 에서 `context.colors` 로 매핑하는 편이 테마와의 결합도 낮다.

### 모델 겹수 — 필요한 곳에만

DTO 는 endpoint 경계마다 둔다. 응답 필드명(`nv`, `pcv`, `aq`)이 앱 어휘와 전혀 다르고, DTO 가 있어야 응답 형식 변화가 한 파일에서 멈춘다.

앱 모델 겹은 아래 중 하나라도 해당할 때만 둔다.

1. 여러 소스를 합친다 — 메타 + 시세 → `Stock`
2. 계산이 붙는다 — 등락액 `nv - pcv`, 등락률 `(nv - pcv) / pcv`, 시가총액 `nv × countOfListedStock` → `Quote`
3. 여러 화면이 공유한다

셋 다 아니고 DTO → 모델이 필드 복사뿐이면 한 겹으로 합친다. 겹수를 맞추려고 의미 없는 변환 코드를 늘리지 않는다. 어떤 데이터를 어떻게 처리했는지는 변경 이력에 기록한다.

### 중복 요청 방지 — 액션 단위로 다르게

- **새로고침** 처럼 같은 요청의 반복은 진행 중이면 무시한다.
- **기간 탭 전환** 은 latest-wins 다. 응답이 도착했을 때 `if (period != _selectedPeriod) return;` 로 오래된 응답을 버린다. 하나의 플래그로 전부 막으면 `1개월 → 3개월` 을 빠르게 눌렀을 때 나중 의도가 무시된다.
- **검색** 은 디바운스 + latest-wins.

### 종목 식별자 — canonical id

앱 내부는 `domestic:{6자리}` 로 다루고, Naver 요청 직전에만 symbol 로 바꾼다. 자동완성 응답에는 지수 · 해외 종목 · IPO 가 섞여 오므로 경계에서 국내 · 6자리만 통과시켜 내부를 단일 규칙으로 유지한다.

### 에러 처리 — 예외를 그대로 던진다

`data` 계층은 예외를 그대로 throw 하고 ViewModel 이 `try/catch` 로 받아 `failed` + `errorMessage` 로 바꾼다. `Result` 래퍼 타입은 만들지 않았다 — 소비 지점이 ViewModel 한 곳뿐이라 래퍼가 주는 이득이 없다.

### 라우팅 · 탭

`Navigator.push(MaterialPageRoute)` 를 쓴다. 화면 3개에 딥링크 요구가 없어 `go_router` 는 과하다. 하단 탭은 `IndexedStack` 으로 두 화면을 유지해 탭을 옮겨도 검색어와 스크롤 위치가 남게 한다.

### 공통 컴포넌트 승격 기준

**두 번째 사용처가 실제로 생겼을 때** `ui/common/` 으로 옮긴다. 미리 공통화하면 쓰이지 않는 파라미터만 늘어난다.

### 테스트 범위

`core/format.dart` 와 일별 시세 파서에 유닛 테스트를 둔다. 깨지면 화면 전체가 틀리고, 위젯 없이 검증할 수 있는 지점이다. 나머지는 `flutter analyze` 로 커버한다.

### 영속성

관심 목록과 정렬 기준의 로컬 저장은 과제의 **선택** 항목이라 필수 항목을 모두 마친 뒤에 진행한다. 하게 되면 `shared_preferences` 를 `FavoritesStore` 내부에서만 다뤄 화면 코드가 저장 방식을 모르게 한다.

---

## 변경 이력

| 날짜 | 항목 | 무엇을 어떻게 바꿨는지 | 왜 |
| --- | --- | --- | --- |
| 2026-09-10 | — | 초기 결정 기록 | 구현 시작 전 기준선 |
| 2026-09-11 | 모델 겹수 | `Stock` · `Quote` · `DailyPrice` 세 겹을 유지했다 | 각각 기준을 충족한다 — `Stock` 은 자동완성과 메타 두 소스를 합치고, `Quote` 는 등락 · 시가총액 계산이 붙고, `DailyPrice` 는 차트와 일별 시세 표가 함께 쓴다. 필드 복사뿐인 겹은 만들지 않았다 |
| 2026-09-11 | 의미 enum 위치 | `PriceTone` · `ChartPeriod` 를 `data/model/` 에 뒀다 | 둘 다 `ui` 와 `data` 양쪽이 쓴다. `ui` 에 두면 `data` 가 `ui` 를 참조해 의존 방향이 뒤집히고, 표시 문자열은 넣지 않아 `data` 의 순수성을 해치지 않는다 |
| 2026-09-11 | 시세 파싱 실패 | 종목 항목 단위로 건너뛰고 결과에서 제외한다 | 관심 목록의 한 종목이 거래정지 등으로 어긋날 때 목록 전체가 실패하는 것을 막는다. 빠진 행은 과제가 이미 요구한 "시세 미수신 스켈레톤" 으로 표현된다 |
| 2026-09-11 | 일별 시세 등락 | **인접 행 종가 차이로 계산하려던 것을 HTML 의 방향 아이콘을 읽는 쪽으로 바꿨다** | 실제 응답을 받아보니 전일비 칸마다 `<em class="bu_p bu_pup/bu_pdn/bu_pn">` 로 방향이 명시돼 있었다. 인접 행 차이는 페이지의 가장 오래된 행에서 값이 비는데, 아이콘을 읽으면 모든 행이 채워진다. 보합(`bu_pn`)은 전일비가 0 이라 부호를 0 으로 둬도 값이 같다 |
| 2026-09-11 | `lastPage` 추출 | `맨뒤` 링크가 없으면 네비게이션의 페이지 번호 최댓값으로 보정한다 | 마지막 페이지(756)에는 `pgRR`(맨뒤) · `pgR`(다음) 링크가 아예 없다. 링크만 믿으면 마지막 페이지에서 `lastPage` 를 못 읽는다 |
| 2026-09-11 | 검색 결과의 시장명 | 자동완성 응답의 `typeName` 을 쓰고 결과마다 메타를 조회하지 않는다 | 자동완성이 이미 `코스피` 를 담아 준다. 결과 10건마다 메타를 부르면 요청이 10배가 된다 |
