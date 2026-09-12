# 과제 2 — Lucy Studio `목표가 알림`

과제 1의 세 화면과 **무관한 새 화면**. 시안이 안내 메일에 있고(`빈 상태` · `등록 다이얼로그` · `등록된 목록` 3상태), 색상·서체·간격은 **과제 1과 같은 디자인 토큰**(`app/lib/theme/README.md` 대응표)을 쓴다.

- 하나의 페이지로 만든다. 페이지 이름은 **`targetAlert`**.
- **데이터 연동 없음.** 실제 시세·알림 없이 사용자 입력값을 그대로 쓴다.
- 제출물은 `cloneProject/assets` 폴더 압축.
- 문서: https://docs.edencrew.com/ — `시작하기`, `Lucy Team Cloud에서 프로젝트 관리하기`, `튜토리얼 & 실습`, `레이아웃 & 화면 설계`, `스타일 & 디자인 시스템`, `위젯 사용`.

**Claude 의 역할** — 문서 조사, 스크립트 작성, 체크리스트 대조까지. GUI 조작은 사용자가 한다.

---

## 준비

- [x] Lucy Studio 설치 (macOS 설치 파일은 안내 메일 링크)
- [x] 계정 생성 · 워크스페이스 초기 설정 — 로그인 상태 확인됨. 토큰 만료일이 09-10 이라 재로그인이 필요할 수 있다
- [ ] 튜토리얼 1회 따라하기 (처음이면 권장)

## 필수

- [ ] 헤더에 `목표가 알림` 제목과 우측 `+` 버튼. `+` 는 **accent 색**
- [ ] **등록된 목록** — 각 행에 좌측 **종목명**, 우측 **목표가**, 행 사이에 구분선
  - [ ] 목표가는 천 단위 구분 쉼표 (예: `200,000`)
  - [ ] **목표가 색이 매도/매수 구분** — 매수 `price/up/text`(빨강) · 매도 `price/down/text`(파랑). 시안이 한 목록에 둘을 섞어 보여준다
  - [ ] **행은 컴포넌트로 분리해 재사용**
- [ ] **빈 상태** — 항목이 하나도 없을 때 아이콘, `등록된 알림이 없습니다`, `우측 상단 + 버튼을 눌러 목표가를 추가해보세요`. 이때도 헤더 유지
- [ ] **등록 다이얼로그** — `+` 버튼으로 열림
  - [ ] 제목 `목표가 알림 추가`
  - [ ] 입력 항목 `종목명`, `목표가` 두 개, 각각 위에 라벨
  - [ ] `목표가` placeholder 는 `숫자만 입력`
  - [ ] 우측 하단에 `매도` 와 `매수` 버튼. **두 버튼 모두 등록**하며, 어느 쪽을 눌렀는지가 항목의 구분이 됨
  - [ ] 닫기는 우측 상단 `x` 아이콘
  - [ ] 다이얼로그가 열려 있을 때 뒤 화면이 어둡게 가려짐
- [ ] **등록하면 입력한 항목이 리스트에 실제로 추가된다** (그려두기만 하면 부족, 눌러서 동작해야 함)
- [ ] `x` 를 누르면 아무것도 추가되지 않고 닫힘
- [ ] 빈 값 검증 (필수는 여기까지)

## 선택

- [ ] 디자인 토큰을 Lucy Studio 가 지원하는 방식으로 정의해 두고 참조
- [ ] 종목명 · 목표가 입력값 검증
- [ ] 항목 삭제

## 직접 판단

- [x] ~~시안에 수치가 없는 여백 · 폰트 크기~~ → 시안 3프레임에서 전부 읽었다. 아래 "시안 스펙" 참고
- [x] ~~목표가에 `원` 같은 단위를 붙일지~~ → **안 붙인다.** 시안이 `200,000` 으로만 쓴다
- [ ] `목표가` 입력을 숫자만 받게 제한할지, 등록 시점에 걸러낼지 — 초안은 **등록 시점에 숫자 아닌 문자를 걸러내는 것**(`replace(/[^0-9]/g, "")`). 입력 중에 막으면 붙여넣기가 불편하다
- [ ] 빈 값일 때 무엇을 보여줄지 — 초안은 **닫지 않고 그대로 둔다**(에러 문구 없음). 시안에 에러 상태가 없다


---

## 시안 스펙 (시안 3프레임에서 읽은 값)

색·서체 이름은 과제 1과 같은 토큰 이름이다 — 대응표는 `app/lib/theme/README.md`.

### 공통

프레임 `393 × 852`, 배경 `surface/base`.

### 헤더 (세 상태 모두 동일)

높이 `52`, 좌우 `16` · 상하 `12`, 양끝 정렬.

| 요소 | 값 |
| --- | --- |
| `목표가 알림` | `title` 19/22 Bold, `text/primary` |
| `ico_plus` | 22 × 22, **accent** |

### 목록 행 — **컴포넌트로 분리해 재사용**

아래 테두리 `border/subtle`, 최소 높이 `56`, 좌우 `16` · 상하 `14`, 요소 간격 `12`.

| 요소 | 값 |
| --- | --- |
| 종목명 | `body` 15/20 Medium, `text/primary`, 남는 폭 차지 |
| 목표가 | `body/num` 15/20 Medium, **매수 = `price/up/text`(빨강) · 매도 = `price/down/text`(파랑)** |

> **목표가의 색이 매도/매수 구분이다.** 시안의 다섯 행이 빨강 셋 · 파랑 둘로 섞여 있다.
> 항목에 `매도`/`매수` 라벨을 따로 달지 않는다.

### 빈 상태

세로 가운데 정렬, 요소 간격 `16`, 아래 여백 `40`, 좌우 `32`.

| 요소 | 값 |
| --- | --- |
| `ico_bellPlus` | 52 × 48 |
| `등록된 알림이 없습니다` | `body` 15/20 Medium, `text/primary` |
| `우측 상단 + 버튼을 눌러` · `목표가를 추가해보세요` | 13/20 **Bold**, `text/tertiary`, 2줄 가운데 정렬 |

두 문구 사이 간격 `6`. **이때도 헤더는 그대로 있다.**

### 등록 다이얼로그

배경 딤은 `surface/scrim`(검정 60%)이 화면 전체를 덮는다.

다이얼로그: 너비 `313`, 배경 `surface/overlay`, 테두리 `border/subtle`, 라운드 `16`,
그림자 `0 12 32 rgba(0,0,0,.6)`, 위 `20` · 좌우 `20` · 아래 `24`, 요소 간격 `24`.

| 요소 | 값 |
| --- | --- |
| `목표가 알림 추가` | `title` 19/22 Bold, `text/primary` |
| `ico_x` | 24 × 24, 제목과 양끝 정렬 |
| 필드 라벨 (`종목명` · `목표가`) | `label` 13/18 **Bold**, `text/secondary` |
| 입력 상자 | 배경 `surface/sunken`, 테두리 `border/strong`, 라운드 `8`, 좌우 `14` · 상하 `11` |
| 입력 글자 | 15/20 Medium, `text/primary` (placeholder 는 `text/tertiary`) |
| `목표가` placeholder | `숫자만 입력` |

라벨과 입력 상자 사이 `6`.

**버튼 줄** — 높이 `48`, 간격 `8`, 둘 다 **같은 폭으로 나눠 가진다**.

| 버튼 | 배경 | 글자 |
| --- | --- | --- |
| `매도` | `price/down/bg` | `price/down/text` (파랑) |
| `매수` | `price/up/bg` | `price/up/text` (빨강) |

라운드 `8`, 글자 15/20 Medium.

---

## 스크립트

API 는 **Lucy Studio 앱 번들의 세 파일로 전부 대조했다**(2026-09-12). 지어낸 이름이 없다.

| 파일 | 무엇이 들어 있나 |
| --- | --- |
| `assets/script/objet/base.objet.json` | **모든 위젯이 상속하는 베이스** — `visible`·`disable`·`tag`, `setProperty`·`setStyleProperty`, `onTap` 계열 |
| `assets/script/modules/schema.json` | 위젯별 `methods` · `setters` · `getters` · `events` (101개 타입) |
| `assets/script/docs/docs.ko.json` | 한국어 설명과 예제 (976항목) |

> `schema.json` 의 `methods` 만 보면 `visible`·`current`·`setProperty` 가 없는 것처럼 보인다.
> 프로퍼티는 `setters`/`getters`, 이벤트는 `events` 에 따로 있고 공통분은 `base.objet.json` 에 있다.

| 필요한 것 | API | 출처 |
| --- | --- | --- |
| 버튼 클릭 | `btn.onClick = fn` | `ButtonObjet.events` |
| 버튼 아닌 위젯 탭 | `위젯.onTap = fn` | **베이스** — Icon·Image·Column 어디에나 붙는다 |
| 보임/숨김 | `위젯.visible = bool` | 베이스 setter. `setProperty("visible", bool)` 도 같은 것 |
| 다이얼로그 열기 | `$form.openDialog(formPath, linkArg, jsCallback, options)` | **콜백이 3번째** |
| 다이얼로그 닫기 + 값 전달 | `$form.closeDialog(result)` → 연 쪽 콜백으로 들어온다 | |
| 폼 로컬 변수 | `$form.setVar(name, value)` / `getVar(name)` / `clearVar(name)` | |
| 반복 위젯 | `list.clear()` · `list.add()` · `list.remove(i)` · `list.count` · `list.current` | `IteratorObjet` |
| **행 하나 갱신** | `list.setState(i, fn)` — 바인딩 스코프를 i 행으로 두고 콜백을 돌린 뒤 그 행만 다시 빌드 | 이 용도의 정식 API |
| 컴포넌트 값 주고받기 | `comp.setVar` · `comp.getVar` · `comp.onVarChanged = (name, value, prev) => {}` | **노출(readwrite) 변수만** |
| 텍스트 쓰기 | `txt.setText(s)` 또는 `txt.text = s` | |
| **텍스트 색을 토큰으로** | `txt.setTextColor("price/up/text")` — 색상 **토큰 문자열**을 받는다 | 행 색을 variant 없이 가른다 |
| 입력값 읽기 | `edt.getText()` 또는 `edt.text` | |
| 스타일 속성 | `위젯.setStyleProperty(styleName, propName, value)` — **3인자** | 베이스 |

### 행 컴포넌트 `AlertRow`

과제가 **"행은 컴포넌트로 분리해 재사용"** 을 필수로 요구한다. 컴포넌트 안의 위젯은
바깥 폼에서 id 로 잡을 수 없다 — 문서가 "노출된(읽기/읽기쓰기) 변수"만 읽고 쓸 수 있고
비공개 변수는 아무 동작도 하지 않는다고 못 박았다. 그래서 주고받을 값을 변수로 노출한다.

| 노출 변수 | 접근 | 쓰임 |
| --- | --- | --- |
| `name` | readwrite | 종목명 |
| `priceLabel` | readwrite | **이미 `200,000` 으로 포맷된 문자열** — 포맷은 부모가 끝낸다 |
| `side` | readwrite | `"buy"` / `"sell"` — 목표가 색을 가른다 |

`name` · `priceLabel` 은 컴포넌트 안에서 Text 의 text 속성에 **바인딩**한다(Binding 탭).
색은 컴포넌트 자신의 스크립트에서 처리한다 — `setTextColor` 가 토큰 문자열을 받으므로
variant 를 따로 만들 필요가 없다.

```js
// 컴포넌트 AlertRow 의 스크립트
function onStart() {
  comp.onVarChanged = function (name, value) {
    if (name === "side") applySide(value);
  };
  applySide(comp.getVar("side"));
}

// 목표가 색이 매도/매수 구분이다. 항목에 라벨을 따로 달지 않는다.
function applySide(side) {
  txtPrice.setTextColor(side === "sell" ? "price/down/text" : "price/up/text");
}
```

> 토큰 이름(`price/up/text`)은 이 프로젝트의 색 토큰 이름과 같아야 한다.
> 스튜디오 색상 패널에서 실제 토큰 이름을 확인하고 맞춘다.

### 페이지 `targetAlert`

```js
function onStart() {
  btnPlus.onClick = openAddDialog;   // + 를 아이콘/이미지로 뒀으면 onTap
  render();
}

// 데이터 연동이 없으므로 폼 로컬 변수 하나면 충분하다.
function alerts() {
  return $form.getVar("alerts") || [];
}

function openAddDialog() {
  // 인자 순서는 (formPath, linkArg, jsCallback, options). 콜백이 options 보다 앞이다.
  $form.openDialog("targetAlertAdd", null, function (result) {
    if (!result) return;             // x 로 닫았거나 배경을 탭한 경우 — 아무것도 추가하지 않는다
    var list = alerts();
    list.push(result);               // { name, price, side }
    $form.setVar("alerts", list);
    render();
  }, { barrierDismissible: true });
}

function render() {
  var list = alerts();

  // 빈 상태와 목록은 둘 중 하나만 보인다. 헤더는 어느 쪽이든 그대로다.
  emptyState.visible = list.length === 0;
  lsvAlert.visible = list.length > 0;

  lsvAlert.clear();
  for (var i = 0; i < list.length; i++) {
    lsvAlert.add();
    // setState 가 바인딩 스코프를 i 행으로 잡아 준다. 그 안의 쓰기는 i 행으로 간다.
    lsvAlert.setState(i, makeRowSetter(list[i]));
  }
}

// 클로저를 루프 밖에서 만든다 — var 는 블록 스코프가 아니라 i 가 공유된다.
function makeRowSetter(item) {
  return function () {
    cmpRow.setVar("name", item.name);
    cmpRow.setVar("priceLabel", thousands(item.price));
    cmpRow.setVar("side", item.side);
  };
}

// 천 단위 구분 쉼표. 과제 1 의 `core/format.dart` 와 같은 규칙이다.
function thousands(value) {
  return String(value).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}
```

### 다이얼로그 폼 `targetAlertAdd`

```js
function onStart() {
  btnClose.onTap = function () { $form.closeDialog(null); };   // x 가 Button 이면 onClick
  btnSell.onClick = function () { submit("sell"); };
  btnBuy.onClick = function () { submit("buy"); };
}

function submit(side) {
  var name = edtName.getText().trim();
  // 입력 중에 막으면 붙여넣기가 불편하다. 등록 시점에 숫자만 남긴다.
  var price = edtPrice.getText().replace(/[^0-9]/g, "");

  // 빈 값 검증까지가 필수다. 둘 중 하나라도 비면 닫지 않는다.
  if (name === "" || price === "") return;

  $form.closeDialog({ name: name, price: Number(price), side: side });
}
```

### 스튜디오에서 확인할 것

API 는 대조가 끝났다. 남은 건 **스튜디오에서만 알 수 있는 것** 넷이다.

- **`onStart` 가 폼 스크립트의 진입점 이름이 맞는지.** 번들 스키마에 없다 — 스크립트 편집기가
  만들어 주는 생명주기 훅이라 편집기에서 확인한다. 이름이 다르면 그 이름으로 바꾼다.
- **`lsvAlert.setState(i, fn)` 안의 `cmpRow.setVar(...)` 가 i 번째 행 인스턴스로 가는지.**
  문서는 "바인딩된 프로퍼티"를 말할 뿐 컴포넌트 변수까지 같은 스코프인지는 적지 않았다.
  두 행을 넣어 확인한다. 아니면 행을 컴포넌트 대신 리스트 안에 직접 그리고(튜토리얼 방식)
  재사용은 컴포넌트를 다른 자리에서 가져다 쓰는 것으로 만족한다.
- **색 토큰 이름** — `price/up/text` · `price/down/text` 가 이 프로젝트에 그 이름으로 있는지.
- 위젯 id 를 위 스크립트와 같은 이름(`btnPlus` · `lsvAlert` · `cmpRow` · `emptyState` ·
  `txtPrice` · `edtName` · `edtPrice` · `btnClose` · `btnSell` · `btnBuy`)으로 맞추면 그대로 붙는다.
  `cmpRow` 는 리스트 안에 놓은 **행 컴포넌트 인스턴스**의 id 다.

---

## GUI 작업 순서

**위험한 것을 먼저 깨뜨린다.** 남은 불확실 두 개(`onStart` 진입점 이름, `setState` 안의
컴포넌트 변수 스코프)가 틀리면 구조가 바뀐다. 예쁘게 만드는 건 그 뒤다.

### 1. 프로젝트와 페이지

- Lucy Team Cloud 에 프로젝트를 만들고 연다. 로컬 `cloneProject/` 는 이때 생긴다.
- 페이지를 **`targetAlert`** 로 만든다. 프레임 `393 × 852`, 배경 `surface/base`.
- 색 토큰 패널에서 **`price/up/text` · `price/down/text` · `surface/scrim` 이 그 이름으로 있는지 확인한다.**
  이름이 다르면 스크립트의 문자열을 그 이름으로 바꾼다.

### 2. 먼저 깨뜨려 볼 것 — 행 컴포넌트와 리스트 (여기서 막히면 나머지 설계가 바뀐다)

1. 컴포넌트 `AlertRow` 를 만든다. 안에는 Text 둘(`txtName` · `txtPrice`)만.
2. 변수 `name` · `priceLabel` · `side` 를 **readwrite 로 노출**한다. 비공개면 바깥에서 아무 일도 안 일어난다.
3. `name` → `txtName`, `priceLabel` → `txtPrice` 의 text 에 바인딩한다.
4. 페이지에 ListView `lsvAlert` 를 놓고 그 안에 `AlertRow` 인스턴스를 놓는다. 인스턴스 id 는 `cmpRow`.
5. **두 행을 서로 다른 값으로 넣어 본다.** 페이지 스크립트에 임시로:
   ```js
   function onStart() {
     lsvAlert.clear();
     lsvAlert.add(); lsvAlert.setState(0, function () { cmpRow.setVar("name", "첫째"); });
     lsvAlert.add(); lsvAlert.setState(1, function () { cmpRow.setVar("name", "둘째"); });
   }
   ```
   두 행이 `첫째` · `둘째` 로 갈리면 통과. **둘 다 같은 값이면 스코프가 안 먹는 것이다** —
   행을 컴포넌트 대신 리스트 안에 직접 그리고(튜토리얼 방식), 재사용은 컴포넌트를
   다른 자리에서 가져다 쓰는 것으로 만족한다. 이때 `AlertRow` 자체는 버리지 않는다.
- 같은 자리에서 **`onStart` 가 실제로 불리는지**도 같이 확인된다. 안 불리면 편집기가
  만들어 주는 훅 이름으로 바꾼다.

### 3. 헤더

높이 `52`, 좌우 `16` · 상하 `12`, 양끝 정렬. `목표가 알림` 19/22 Bold `text/primary`,
우측 `ico_plus` 22×22 **accent**. id 는 `btnPlus`.

> `+` 를 Button 으로 두면 `onClick`, 아이콘/이미지로 두면 `onTap`. **둘 다 실재한다** —
> `onTap` 은 모든 위젯이 상속하므로 어느 쪽을 골라도 된다.

### 4. 빈 상태 `emptyState`

세로 가운데, 요소 간격 `16`, 아래 여백 `40`, 좌우 `32`.
`ico_bellPlus` 52×48 → `등록된 알림이 없습니다` 15/20 Medium `text/primary` →
안내 2줄 13/20 **Bold** `text/tertiary`(두 문구 사이 `6`).

`emptyState.visible` 로 껐다 켜므로 **하나의 컨테이너로 묶어 id 를 준다.**
헤더는 이 컨테이너 **밖**에 둔다 — 빈 상태에서도 헤더는 남아야 한다.

### 5. 행 색 스크립트

`AlertRow` 컴포넌트 스크립트에 `onVarChanged` 로 `side` 를 받아 `txtPrice.setTextColor(...)`.
**매수 = 빨강(`price/up/text`) · 매도 = 파랑(`price/down/text`).** 과제 1 과 같은 방향이다.

### 6. 다이얼로그 폼 `targetAlertAdd`

너비 `313`, 배경 `surface/overlay`, 테두리 `border/subtle`, 라운드 `16`,
위 `20` · 좌우 `20` · 아래 `24`, 요소 간격 `24`. 딤은 `surface/scrim`.

제목 `목표가 알림 추가` + 우측 `ico_x` 24×24(`btnClose`) → 라벨+입력 둘
(`edtName` · `edtPrice`, placeholder `숫자만 입력`) → 버튼 줄
(`btnSell` · `btnBuy`, 높이 `48`, 간격 `8`, **같은 폭으로 나눠 가진다**).

### 7. 스크립트 붙이고 동작 확인

임시 스크립트를 지우고 위의 `targetAlert` · `targetAlertAdd` 스크립트를 넣는다. 그다음:

- `+` → 다이얼로그가 열리고 뒤가 어두워진다
- **매수로 하나, 매도로 하나 등록** → 목록에 둘 다 뜨고 **목표가 색이 빨강·파랑으로 갈린다**
- 목표가가 `200,000` 처럼 쉼표로 끊긴다
- `x` → 아무것도 추가되지 않고 닫힌다
- 종목명이나 목표가를 비우고 `매수` → 닫히지 않는다
- 전부 지우면 빈 상태가 다시 나오고 **헤더는 남아 있다**

---

## 제출

- [ ] 페이지 이름이 `targetAlert` 인지 재확인
- [ ] `cloneProject/assets` 를 한 번에 압축 → `~/edenCrew/lucy/` 에 보관
- [ ] `unzip -l` 로 내용 확인
