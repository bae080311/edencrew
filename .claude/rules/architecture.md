# 아키텍처

`lib/` 에 코드를 쓰기 전에 읽는다. 여기 있는 건 바꾸면 전면 수정이 되는 것들이다. 폴더 구조는 `CLAUDE.md` 에 있다.

## 고정 규칙 (바꾸면 전면 수정 — 바꾸기 전에 반드시 확인)

의존 방향 · 관심 상태 단일 원천 · 포맷 단일 지점은 `critical.md` 3~5번. 여기서는 나머지 둘만 다룬다.

| 규칙 | 내용 |
| --- | --- |
| 캐시 | 일별 시세 페이지 캐시 · 메타 캐시는 **repository 내부**에 숨긴다. ViewModel은 캐시를 모른다 |
| 목업 | `StockRepository` 추상 + `FakeStockRepository`(`assets/mock/`을 **실제와 같은 파서**로 읽음). `--dart-define=USE_FAKE=true` 분기는 `main.dart`에서만 |

## UI 모델 — 타입이 아니라 책임

규칙은 하나: **View는 비즈니스 계산을 하지 않는다.** 타입 제한은 없다 — 차트 좌표 · 인덱스 · 비율처럼 UI가 숫자를 필요로 하면 `double`/`int`를 그대로 담는다.

금지 두 가지:
- View에서 표시 문자열 만들기 — `sort`, `toStringAsFixed`, 천단위 삽입, `DateTime` 연산, 등락 계산은 ViewModel / `core/format.dart` 몫.
- UI 모델에 `Color`/`TextStyle`/`Widget` 담기 — 토큰 접근에 `BuildContext`가 필요해 UI 모델에서 만들 수 없다. `PriceTone { up, down, flat }` 같은 의미 enum으로 넘기고 View에서 `context.colors`로 매핑한다.

화면 상태는 `enum LoadState { initial, loading, ready, failed }` + `String? errorMessage`(failed에서만) + `bool isRefreshing`(ready에서 기존 목록 유지하며 갱신). 빈 상태는 `ready && rows.isEmpty`로 **파생**시키고 별도 플래그를 두지 않는다. 행 단위 스켈레톤은 행 모델의 `isSkeleton`.

중복 요청은 액션 단위로 다르게 막는다 — 새로고침 같은 동일 요청은 `_refreshing` 가드로 무시, **기간 탭 전환은 latest-wins**(응답 도착 시 `if (period != _selectedPeriod) return;`), 검색은 디바운스 + latest-wins.

## 모델 겹수 — "항상 3단계"가 아니다

`Naver 응답 → DTO → (앱 모델) → UI 모델 → View`

- **DTO는 endpoint 경계마다 둔다.** `NAVER_API.md`가 DTO 작성을 필수로 명시했다. 필드명은 Naver 원본(`nv`, `pcv`, `aq`) 유지, 계산 · 포맷 금지.
- **앱 모델 겹은 값이 있을 때만.** ①여러 소스를 합치는가 ②계산이 붙는가 ③여러 화면이 공유하는가 — 셋 다 아니고 필드 복사뿐이면 한 겹으로 합치고, **합친 이유를 `ARCHITECTURE.md`에 적는다.**

## 화면 추가 절차

①UI 모델 필드 정의 → ②ViewModel(`ChangeNotifier`, repository를 생성자로 주입) → ③View(UI 코드만) → ④**두 번째 사용처가 생길 때** `ui/common/`으로 승격 → ⑤`main.dart`에 등록.
