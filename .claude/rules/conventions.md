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
- `main` 직접 커밋. 하루 최소 1회 푸시.
