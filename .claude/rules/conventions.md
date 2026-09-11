# 네이밍 · Git

파일이나 심볼 이름을 정할 때, 커밋할 때 읽는다. 커밋을 쪼개는 절차는 `.claude/skills/commit-step/SKILL.md`.

## 네이밍

**이름은 내용을 말한다. 순번으로 짓지 않는다.** `task1` · `step2` · `doc3` · `new_` · `temp_` 처럼 열어보기 전엔 뭔지 모르는 이름은 쓰지 않는다 — 파일이든 클래스든 변수든 같다. 둘 이상이 같은 계열이면 번호를 붙이는 대신 각자의 내용으로 구분한다(`flutter-app.md` / `lucy-target-alert.md`).

문서 · 에셋 파일명은 영어 소문자 kebab-case(`lucy-target-alert.md`), Dart 파일은 snake_case(`sise_day_parser.dart`).


`*_dto.dart`/`*Dto` · `*_repository.dart`/`*Repository` · `*_store.dart`/`*Store` · `*_view.dart`/`*View` · `*_view_model.dart`/`*ViewModel` · `*_ui_model.dart`/`*Ui`,`*RowUi` · `naver_api.dart`/`NaverApi`, `sise_day_parser.dart`/`SiseDayParser` · `<대상>_test.dart`.

- 화면 폴더는 기능명 단수(`watchlist`, `search`, `detail`). `screen`/`page` 접미사는 쓰지 않는다.
- bool은 `is`/`has`/`can` 접두. 원격 조회 `fetch*`, 화면 로드 `load*`, 사용자 액션은 동사 원형(`refresh()`, `toggleFavorite()`).
- mock 파일은 `assets/mock/<endpoint>_<식별자>.json|html`.
- 접미사를 바꾸면 `.claude/hooks/dart-check.sh`의 grep도 같이 고친다.

## Git

커밋 전 검사와 자동 커밋 금지는 `critical.md` 7번. 커밋이 끝나면 `.claude/plan/flow.md` 의 해당 체크박스를 켠다.

- **작업 단위로 커밋한다**(평가 항목). 한 커밋 = 한 논리 변경. 화면 코드와 무관한 리팩터 · 문서를 같은 커밋에 섞지 않는다.
- 메시지: `feat|fix|refactor|style|docs|test|chore: <한국어 제목>`. scope 안 붙임. 본문은 필요할 때만, **왜**를 적는다.
- **`Co-Authored-By` 등 AI attribution 라인을 붙이지 않는다.** AI 활용 범위는 `README.md`에 한 문단으로 남긴다.
- 푸시된 커밋에 `--amend`, `rebase`, `push --force` 금지 — 평가자가 과정을 본다.
- 하루 최소 1회 푸시.

## 브랜치

**`main` 에 직접 커밋하지 않는다. 작업마다 새 브랜치를 판다.**

1. 시작 전 `git switch main && git pull` 로 최신화하고 `git switch -c <type>/<내용>` 으로 판다.
   - `<type>` 은 커밋 타입과 같다(`feat` · `fix` · `refactor` · `docs` · `test` · `chore`).
   - `<내용>` 은 kebab-case 로 **무엇을 하는지**. 순번으로 짓지 않는다 — `feat/sise-day-parser` 지 `feat/step2` 가 아니다.
2. **브랜치 하나 = 독립적으로 끝나는 작업 하나.** 파서 하나, 화면 하나. 커밋은 그 안에서 논리 단위로 쪼갠다(보통 2~5개).
3. **작은 건 새로 파지 말고 진행 중인 브랜치에 얹는다.** 규칙 한 줄, 오타, 방금 올린 PR 의 보완처럼 혼자서는 PR 을 열 만큼이 아닌 변경이 그렇다. 기준은 *되돌릴 때 같이 되돌려도 괜찮은가* — 그렇다면 얹고, 따로 되돌려야 한다면 새 브랜치. PR 이 3개씩 열려 있으면 이미 너무 쪼갠 것이다.
4. 끝나면 `git push -u origin <브랜치>` → `gh pr create`. PR 제목은 커밋 제목과 같은 형식, 본문은 `.github/pull_request_template.md` 형식(설명 · 작업 내용 · 리뷰 요구사항)을 따른다.
5. **머지는 사용자 승인 후에만.** 승인되면 머지하고 `git switch main && git pull`, 브랜치 삭제.
6. 실수로 `main` 에서 작업을 시작했으면 커밋하기 전에 `git switch -c` 로 옮긴다. 이미 커밋했고 푸시 전이면 브랜치를 만들어 옮기고 `main` 을 되돌린다.

PR 본문에도 AI attribution 라인을 붙이지 않는다(위 커밋 규칙과 같다).
