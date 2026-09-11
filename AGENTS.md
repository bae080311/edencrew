# AGENTS.md

**먼저 `CLAUDE.md` 와 `.claude/rules/critical.md` 를 읽어라.** CLAUDE.md 는 지도고, 규칙은 `.claude/rules/` 에 주제별로 있다 — 어느 걸 언제 읽는지는 CLAUDE.md 의 표에 있다. 아래는 Codex 에만 해당하는 보충이다. 규칙은 여기 복사하지 않는다 — 복사본은 반드시 어긋난다.

## 훅이 없으므로 직접 실행한다

Claude Code 에서는 아래가 훅으로 자동 실행되지만 Codex 에는 훅이 없다.

| 언제 | 무엇을 |
| --- | --- |
| `.dart` 파일을 쓰거나 고친 직후 | `.claude/hooks/dart-check.sh <파일>` — 포맷 + 아키텍처 규칙 grep. 경고가 나오면 고치고 다시 돌린다 |
| `git push` 직후 | `.claude/hooks/handoff.sh write` → `.claude/HANDOFF.md` 의 `## 메모` 두 줄(막힌 곳 / 다음 첫 작업)을 채운다. `## 사실` 은 스크립트 몫이니 건드리지 않는다 |
| 세션 시작 | `.claude/hooks/handoff.sh read` — 지난 세션 핸드오프와 지금 Phase |

## 어디를 보나

- 오늘 할 일 — `.claude/plan/flow.md` 의 첫 미완료 Phase. 항목이 끝나면 그 자리에서 체크박스를 켠다.
- 브랜치 · 커밋 절차 — `.claude/rules/conventions.md` 의 브랜치 절과 `.claude/skills/commit-step/SKILL.md`. **`main` 직접 커밋 금지.**
- 요구사항 원문 — `app/docs/ASSIGNMENT.md`, `app/docs/NAVER_API.md`. 대조 체크리스트는 `.claude/plan/flutter-app.md` · `lucy-target-alert.md`.
- 원문 대조 리뷰 — Codex 에는 서브에이전트가 없으니 `.claude/agents/assignment-reviewer.md` 의 절차를 직접 따라 수행한다.

## 틀리면 바로 감점되는 것

`.claude/rules/critical.md` 여덟 줄. **코드를 쓰기 전에 그 파일을 먼저 연다.** 등락 색 반전 · 토큰 우회 · batch 시세 · EUC-KR 처럼 되돌리기 비싼 것들이 거기 모여 있다.
