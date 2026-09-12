# 이든크루 Flutter 과제

국내 주식 관심종목 앱 화면 3개(관심 · 검색 · 종목상세)를 Flutter 로 구현한다. 마감 **2026-09-14 23:59**.
다크 테마 단일 모드, 프레임 393×852 기준. 여백 · 폰트 크기 · 색은 Figma 값 그대로.

## 문서

| 무엇 | 어디 |
| --- | --- |
| 요구사항 원문 — **충돌하면 이쪽이 이긴다** | `docs/ASSIGNMENT.md` · `docs/NAVER_API.md` · `app/lib/theme/README.md` |
| 안내 메일 요지 (기간 · 링크 · 제출 형식) | `.claude/plan/brief.md` — **커밋 금지**(gitignore) |
| 학습 원장 | `.claude/flywheel/learnings.md` — 뒷다리를 잡은 일, 두 번 나오면 rule 로 승격 |
| 진행 — 일정 · 체크리스트 | `.claude/plan/` — `flow.md`(일자별 할 일 · 컷 라인, **진행 단일 소스**) · `flutter-app.md` · `lucy-target-alert.md`(요구사항 대조) |
| 아키텍처 결정 근거 | `ARCHITECTURE.md` — 결정을 바꿨으면 **바꾼 이유를 거기에 남긴다** |
| 직접 판단한 것 | `README.md` "직접 판단한 부분" |

## 폴더 구조

```
app/lib/
├── main.dart          # 진입점 + DI 조립(MultiProvider)만. 위젯 금지
├── app.dart           # MaterialApp 조립
├── theme/             # 스타터 토큰 — 값 수정 금지, 추가만(이유를 README에)
├── core/format.dart   # 포맷 단일 지점
├── data/{dto,mapper,source,model,repository}/
├── state/favorites_store.dart
└── ui/{common,watchlist,search,detail}/, app_shell.dart
```

## Rule 레이어 — 손대기 전에 해당 파일을 읽는다

CLAUDE.md 는 지도다. 실제 규칙은 아래 파일에 있고, **작업 종류에 맞는 것을 열어보고 시작한다.**

| 언제 | 읽을 것 |
| --- | --- |
| **언제나 — 무엇을 하든 시작 전** | `.claude/rules/critical.md` — 틀리면 바로 감점되는 아홉 가지 |
| `lib/` 에 코드를 쓰기 전 | `.claude/rules/architecture.md` — 의존 방향 · UI 모델 책임 · 모델 겹수 · 화면 추가 절차 |
| 화면 · 위젯을 만들 때 | `.claude/rules/ui.md` — 토큰 사용법 · 기기 레이아웃 |
| `data/` 를 만질 때 | `.claude/rules/data.md` — Naver 응답 함정 |
| 로직을 추가했을 때 | `.claude/rules/testing.md` — 무엇을 어떻게 테스트하나 |
| 이름을 정하거나 커밋할 때 | `.claude/rules/conventions.md` — 네이밍 · Git |
| 작업 하나를 끝냈을 때 | `.claude/plan/flow.md` — 해당 체크박스를 그 자리에서 켠다 |

## 작업 규칙

- Figma 에 없어 직접 판단한 것(토스트 지속시간, 로딩 · 에러, 오버플로, 시세 미수신 행의 정렬 위치 등)은 **결정할 때마다 그때그때** `README.md` 에 한 줄 추가한다. 마지막에 몰아 쓰면 반드시 빠뜨린다. 과제가 "이 부분을 비중 있게 봅니다"라고 명시했다.
- 면접에서 설명할 수 없는 코드는 쓰지 않는다.
- **뒷다리를 잡은 일은 `.claude/flywheel/learnings.md` 에 한 줄.** 같은 게 두 번 나오면 rule 로 승격한다. 고친 그 자리에서 적는다.
- **사용자가 결정할 문제는 그 자리에서 묻는다.** 몇 가지 안과 직접 말할 선택지를 함께 준다. 답에 의존하지 않는 작업은 먼저 끝내두고, 질문만 미루지 않는다.
- Figma 작업은 `figma:figma-design-to-code` 스킬을 쓴다.
- 식별자 · 파일명은 영어, 화면에 보이는 문자열은 한국어 리터럴 그대로(l10n 안 함). **새로 쓰는 코드 주석은 한국어.**
- **주석은 필요한 곳에만 짧게.** 코드가 이미 말하는 것(무엇을 하는지)은 적지 않고, 코드로 드러나지 않는 것만 한 줄로 남긴다 — 왜 이 값인지, 왜 이 순서인지, Naver 응답의 함정 같은 것. 구분선 배너 · 문단 설명 · 죽은 코드 주석 처리는 하지 않는다.

## 점검

| 무엇 | 어떻게 |
| --- | --- |
| 뭐가 남았나 | `assignment-auditor` 에이전트 |
| 있는 게 원문대로 맞나 | `assignment-reviewer` 에이전트 |
| 커밋 쪼개기 | `/commit-step` |
| 제출 전 최종 | `/submit-check` |
