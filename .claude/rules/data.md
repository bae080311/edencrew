# Naver 데이터

`data/` 를 만지기 전에 읽는다. 상세 명세는 `app/docs/NAVER_API.md` 원문이 기준이다.

## 완료 기준은 실제 연동이다

`NAVER_API.md` 가 필수로 못 박은 건 **요청 · 파싱 · DTO 작성 · 모델 연결 네 가지**다. mock 은 "네트워크가 막힐 때" 절의 **권장 사항**일 뿐이고(커밋하면 리뷰에 도움이 된다고만 적혀 있다), 제출물의 동작이 아니다.

- 앱의 **기본 동작은 실제 endpoint 조회**다. `NaverStockRepository` 가 기본이고 `--dart-define=USE_FAKE=true` 는 개발용 옵트인이다.
- mock 은 ①파싱 로직을 고정 입력으로 확정할 때 ②테스트 입력 ③네트워크가 막힌 구간에서 UI 를 진행할 때 쓴다. **여기서 멈추면 미구현이다.**
- 화면 하나를 끝냈다고 치기 전에 `USE_FAKE` 없이 **실제로 값이 들어오는지** 확인한다. endpoint 4개 모두.


## Naver 데이터 함정

- `sise_day.naver` 응답은 **EUC-KR**이다. UTF-8로 디코딩하면 한글이 깨진다.
- 표 숫자 순서는 `종가 · 전일비 · 시가 · 고가 · 저가 · 거래량`.
- 1페이지 = 10거래일. 기간별 필요 페이지 **1M/2 · 3M/6 · 6M/12 · 1Y/25**. 재사용과 `lastPage` 규칙은 `critical.md` 6번.
- 실시간 시세 batch 쿼리 형식은 `query=SERVICE_ITEM:c1,c2,...` (`critical.md` 6번).
- 개발 중에는 응답을 `app/assets/mock/`에 저장해 쓰고, 그 파일도 커밋한다.
