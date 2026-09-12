# 저장해 둔 Naver 응답

`--dart-define=USE_FAKE=true` 일 때 `FakeStockRepository` 가 읽고, 파서 · DTO 유닛 테스트의 고정 입력으로도 쓴다.
**실제 응답 바이트 그대로** 저장했다 — 아래 두 파일은 EUC-KR 이라 UTF-8 로 변환하면 안 된다.

| 파일 | endpoint | 인코딩 |
| --- | --- | --- |
| `ac_samsung.json` | 검색 자동완성 (`q=삼성`) | UTF-8 |
| `realtime_batch.json` | 실시간 시세 — 3종목 batch 조회 | **EUC-KR** |
| `meta_005930.json` | 종목 메타데이터 | UTF-8 |
| `sise_day_005930_p1.html` | 일별 시세 1페이지 — 상승 · 하락 · 보합 세 방향이 모두 들어 있다 | **EUC-KR** |
| `sise_day_005930_p2.html` | 일별 시세 2페이지 — 페이지 이어받기 확인용 | **EUC-KR** |
| `sise_day_005930_last.html` | 일별 시세 마지막 페이지(756) — `맨뒤` 링크가 없는 경계 | **EUC-KR** |

**한 번 저장한 뒤에는 다시 받지 않는다.** 장중에 재다운로드하면 시세가 바뀌어 테스트의 기대값이 어긋난다.
