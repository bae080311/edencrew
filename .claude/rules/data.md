# Naver 데이터

`data/` 를 만지기 전에 읽는다. 상세 명세는 `app/docs/NAVER_API.md` 원문이 기준이다.

## 완료 기준은 실제 연동이다

`NAVER_API.md` 가 필수로 못 박은 건 **요청 · 파싱 · DTO 작성 · 모델 연결 네 가지**다. mock 은 "네트워크가 막힐 때" 절의 **권장 사항**일 뿐이고(커밋하면 리뷰에 도움이 된다고만 적혀 있다), 제출물의 동작이 아니다.

- 앱의 **기본 동작은 실제 endpoint 조회**다. `NaverStockRepository` 가 기본이고 `--dart-define=USE_FAKE=true` 는 개발용 옵트인이다.
- mock 은 ①파싱 로직을 고정 입력으로 확정할 때 ②테스트 입력 ③네트워크가 막힌 구간에서 UI 를 진행할 때 쓴다. **여기서 멈추면 미구현이다.**
- 화면 하나를 끝냈다고 치기 전에 `USE_FAKE` 없이 **실제로 값이 들어오는지** 확인한다. endpoint 4개 모두.


## Naver 데이터 함정

- **EUC-KR 인 응답이 둘이다** — `sise_day.naver`(HTML)와 `polling.finance.naver.com`(실시간 시세 **JSON**). UTF-8 로 디코딩하면 종목명이 깨진다. `NAVER_API.md` 는 HTML 만 경고했으니 믿지 말고 `Content-Type` 의 charset 을 확인한다. 자동완성 · 메타는 UTF-8.
- 디코딩은 **`cp949_codec`** 의 `cp949.decode(bytes)` 로 한다(CP949 ⊃ EUC-KR). `dart:convert` 의 `Encoding` 구현이라 `utf8` 자리에 그대로 들어간다.
  `charset` 의 `eucKr` 은 **쓰지 않는다** — 내부 테이블 이름이 반대로 붙어 디코딩이 깨져 있다. `charset_converter` 는 플랫폼 채널이라 유닛 테스트에서 못 돈다.
- 실시간 시세의 `cv` · `cr` 에는 **부호가 없다**(방향은 `rf` 코드). 등락은 명세대로 `nv - pcv` 로 직접 계산한다.
- **`finance.naver.com` 은 브라우저 User-Agent 를 요구한다.** Dart 기본 UA(`Dart/3.x (dart:io)`)로 요청하면 표 대신 에러 페이지가 200 으로 온다 — 데이터 행 0개. `NaverApi` 가 헤더를 붙인다.
- 표 숫자 순서는 `종가 · 전일비 · 시가 · 고가 · 저가 · 거래량`. 전일비는 **절대값**이고 방향은 `<em class="bu_p bu_pup/bu_pdn/bu_pn">` 에만 있다.
- `lastPage` 는 `맨뒤`(`pgRR`) 링크에서 읽되, **마지막 페이지에는 그 링크가 없다** — 네비게이션의 페이지 번호 최댓값으로 보정한다.
- **저장한 mock 은 다시 받지 않는다.** 장중에 재다운로드하면 시세가 바뀌어 고정 입력이 아니게 되고 테스트가 깨진다.
- 1페이지 = 10거래일. 기간별 필요 페이지 **1M/2 · 3M/6 · 6M/12 · 1Y/25**. 재사용과 `lastPage` 규칙은 `critical.md` 6번.
- 실시간 시세 batch 쿼리 형식은 `query=SERVICE_ITEM:c1,c2,...` (`critical.md` 6번).
- 개발 중에는 응답을 `app/assets/mock/`에 저장해 쓰고, 그 파일도 커밋한다.
