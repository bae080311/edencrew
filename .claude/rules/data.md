# Naver 데이터

`data/` 를 만지기 전에 읽는다. 상세 명세는 `app/docs/NAVER_API.md` 원문이 기준이다.

## Naver 데이터 함정

- `sise_day.naver` 응답은 **EUC-KR**이다. UTF-8로 디코딩하면 한글이 깨진다.
- 표 숫자 순서는 `종가 · 전일비 · 시가 · 고가 · 저가 · 거래량`.
- 1페이지 = 10거래일. 기간별 필요 페이지 **1M/2 · 3M/6 · 6M/12 · 1Y/25**. 재사용과 `lastPage` 규칙은 `critical.md` 6번.
- 실시간 시세 batch 쿼리 형식은 `query=SERVICE_ITEM:c1,c2,...` (`critical.md` 6번).
- 개발 중에는 응답을 `app/assets/mock/`에 저장해 쓰고, 그 파일도 커밋한다.
