# 절대 어기지 않는 것

**작업 종류와 무관하게 시작 전에 읽는다.** 틀리면 바로 감점되거나 전면 수정이 되는 아홉 가지다.
여기 있는 문장이 원본이고, 각 줄의 상세 · 이유 · 적용 방법은 옆에 적힌 rule 파일에 있다.

1. **상승 = 빨강 `priceUpText` / 하락 = 파랑 `priceDownText`**, 보합 `priceFlatText`·`priceFlatBg`. 과제 원문이 "반대로 구현하지 않도록 주의"라고 따로 적은 지점이다. → `ui.md`
2. 색 · 간격 · 서체는 `context.colors.*` / `context.dimens.*` / `AppTypography.*` 만 쓴다. hex 리터럴 · `Colors.*` · `AppPalette` 직접 참조 금지. `lib/theme/` 의 값은 수정하지 않는다(추가만, 이유를 README 에). → `ui.md`
3. 의존 방향은 `ui` → `state` / 추상 `StockRepository` / `data/model` / `core` / `theme` **단방향**. `ui` 에서 `data/dto` · `data/source` · 구체 repository 를 import 하지 않고, `data` 는 `package:flutter/*` 를 import 하지 않는다. → `architecture.md`
4. 관심 상태는 `state/favorites_store.dart` **하나**가 단일 원천. 화면별 복제 금지 — 3화면 동기화는 "같은 객체를 본다"로 해결한다. → `architecture.md`
5. 숫자 · 날짜 포맷은 `core/format.dart` **에서만**. View 는 비즈니스 계산을 하지 않는다. → `architecture.md`
6. 실시간 시세는 `SERVICE_ITEM:` 으로 **한 번에** 조회(종목별 반복 호출 금지). 일별 시세는 **EUC-KR**, `lastPage` 초과 요청 금지, **받은 페이지는 재사용**. 셋 다 평가 항목이다. → `data.md`
7. 커밋 전 `flutter analyze` 무경고 **와** `flutter test` 통과. **자동 커밋 금지** — 사용자가 요청할 때만 커밋하고, 쌓이면 알려만 준다. → `conventions.md` · `testing.md`
8. 새 패키지는 `provider` · `http` 외에 추가하기 전에 **물어본다.**
9. **Figma 시안 · Lucy Studio 설치 파일은 외부에 공개하지 않는다.** 안내 메일이 "평가 목적으로만 제공, 외부 공개·공유 금지"라고 명시했다. 저장소가 **public** 이므로 커밋되는 파일(README · 문서 · 코드 주석 · 커밋 메시지)에 Figma 링크나 설치 파일 링크를 적지 않는다. 원본 링크는 `.claude/plan/brief.md`(gitignore)에만 둔다. → `plan/brief.md`
