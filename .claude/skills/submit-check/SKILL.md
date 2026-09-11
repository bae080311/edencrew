---
name: submit-check
description: 제출 전 최종 점검. 정적 분석·테스트·필수 항목 감사·README 섹션·커밋 분할·과제2 압축을 순서대로 확인하고 메일 초안까지 정리한다. "제출 점검", "제출 준비", /submit-check 에서 사용.
---

# 제출 전 점검

마감 **2026-09-14 23:59**. 아래를 순서대로 확인하고, 각 항목을 `OK` / `문제 있음(내용)` 으로 보고한다. 문제를 발견하면 고치기 전에 **먼저 전체 목록을 보고한다** — 남은 시간에 따라 무엇을 포기할지는 사용자가 정한다.

## 1. 정적 분석 · 테스트

```bash
cd app && flutter analyze
cd app && flutter test
```

`flutter analyze` 무경고는 과제가 명시한 필수다. 테스트는 선택이지만 작성했다면 실행 결과를 README 에 적어야 한다.

## 2. 필수 항목 감사

`assignment-auditor` 와 `assignment-reviewer` 를 **같이 실행한다**(한 메시지에서 병렬로).

- `assignment-auditor` — 남은 필수 항목. 있으면 **마감까지 남은 시간과 함께** 보고한다.
- `assignment-reviewer` — 구현된 것이 과제 원문대로인지. 색 반전 · 표기 형식 · 문구 · 토큰 우회처럼 "있는데 틀린" 것을 잡는다.

둘의 결과를 합쳐 보고한다. 리뷰어가 "확인 불가"로 넘긴 항목은 사용자가 Figma 와 직접 대조해야 하므로 따로 묶어 보여준다.

## 3. README 필수 섹션

`README.md` 에 아래가 다 있는지 확인한다. 과제가 이 목차를 그대로 요구한다.

- [ ] **실행 방법** — Flutter 버전, 실행 명령, 확인한 플랫폼·기기, 폰트 처리 방식
- [ ] **구현 범위** — 필수 중 완료/남은 것, 추가로 한 선택 항목, `flutter test` 결과
- [ ] **기술 선택과 이유** — 상태관리, 폴더 구조, 아키텍처 패턴, 주요 패키지, 차트 처리 방식, 토큰을 추가했다면 그 이유
- [ ] **직접 판단한 부분과 이유** — 토스트 노출 시간·사라지는 방식, 로딩/네트워크 에러/긴 종목명 오버플로, 시세 못 받은 행의 정렬, Figma 와 다르게 구현한 부분
- [ ] **막혔던 지점과 어떻게 접근했는지**
- [ ] AI 도구를 어떤 범위로 썼고 어떤 부분을 직접 재작성했는지 한 문단
- [ ] `docs/ARCHITECTURE.md` 링크

스타터 README 가 그대로 남아 있으면 안 된다(본인 프로젝트 문서로 덮어쓰라는 요구).

## 4. 커밋 · 저장소

```bash
git log --oneline | head -30
git status --short
```

- 커밋이 작업 단위로 쪼개져 있는지(한두 개로 몰려 있으면 문제).
- 커밋 안 된 변경이 없는지, 푸시가 끝났는지.
- 저장소 visibility 가 **public** 인지: `gh repo view --json visibility -q .visibility`.
- `assets/mock/` 이 커밋되어 있는지.

## 5. 과제 2

- `.claude/plan/lucy-target-alert.md` 필수 항목 확인.
- Lucy Studio 페이지 이름이 `targetAlert` 인지.
- `cloneProject/assets` 를 압축: `cd <프로젝트 경로> && zip -r ~/edenCrew/lucy/targetAlert-assets.zip assets`
- 압축 파일 안에 실제 내용이 들어갔는지 `unzip -l` 로 확인.

## 6. 메일 초안

제목: `[과제 제출] Flutter 신입 개발자 과제 - 배경진` — **안내 메일이 지정한 형식**이다. `app/docs/ASSIGNMENT.md` 의 `[Flutter 과제] 홍길동` 은 템플릿 예시이므로 따르지 않는다(`.claude/plan/brief.md`).

본문에 담을 것:
- 과제 1 GitHub 저장소 링크 (public)
- 과제 2 `cloneProject/assets` 압축 파일 첨부
- 미완성 항목이 있으면 **무엇이 왜 남았는지 · 어떻게 구현하려 했는지 · 향후 진행 방향**. 안내 메일이 "간략한 설명(리뷰)을 남겨주시면 평가에 반영"이라고 명시했다.
- 첨부는 과제 2 assets `.zip`.
- 커밋되는 파일에 Figma·설치 파일 링크가 들어가지 않았는지 확인(`critical.md` 9번): `grep -rn "figma.com\|drive.google.com" --include="*.md" --include="*.dart" app/`

초안을 작성해 보여주고, 발송은 사용자가 직접 한다.
