# 과제 2 — Lucy Studio `목표가 알림`

과제 1의 세 화면과 **무관한 새 화면**. 시안이 안내 메일에 있고(`빈 상태` · `등록 다이얼로그` · `등록된 목록` 3상태), 색상·서체·간격은 **과제 1과 같은 디자인 토큰**(`app/lib/theme/README.md` 대응표)을 쓴다.

- 하나의 페이지로 만든다. 페이지 이름은 **`targetAlert`**.
- **데이터 연동 없음.** 실제 시세·알림 없이 사용자 입력값을 그대로 쓴다.
- 제출물은 `cloneProject/assets` 폴더 압축.
- 문서: https://docs.edencrew.com/ — `시작하기`, `Lucy Team Cloud에서 프로젝트 관리하기`, `튜토리얼 & 실습`, `레이아웃 & 화면 설계`, `스타일 & 디자인 시스템`, `위젯 사용`.

**Claude 의 역할** — 문서 조사, 스크립트 작성, 체크리스트 대조까지. GUI 조작은 사용자가 한다.

---

## 준비

- [ ] Lucy Studio 설치 (macOS 설치 파일은 안내 메일 링크)
- [ ] 계정 생성 · 워크스페이스 초기 설정
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

API 이름은 **Lucy Studio 에 들어있는 한국어 스크립트 문서**(`docs.ko.json`)와
`docs.edencrew.com` 의 `로직 & 스크립팅` · `튜토리얼` 에서 확인한 것이다. 지어낸 이름이 없다.

| 필요한 것 | API |
| --- | --- |
| 이벤트 연결 | `onStart()` 안에서 `위젯.onClick = 함수` (아이콘 이미지면 `onTap`) |
| 다이얼로그 열기 | `$form.openDialog(폼경로, linkArg, options, 콜백)` — `options.barrierDismissible` 기본 `true` |
| 다이얼로그 닫기 + 값 전달 | `$form.closeDialog(result)` → 연 쪽의 콜백으로 들어온다 |
| 폼 로컬 변수 | `$form.setVar(이름, 값)` / `$form.getVar(이름)` |
| 반복 위젯(리스트) | `list.clear()` · `list.add()` · `list.current = i` · `list.remove(i)` · `list.count` |
| 텍스트 쓰기 | `txt.setText("...")` |
| 입력값 읽기 | `edt.getText()` (또는 `edt.text`) |
| 속성 · 스타일 | `위젯.setProperty(이름, 값)` · `위젯.setStyleProperty(타입, 경로, 값)` |

> `list.current = i` 를 설정하면 **그 뒤의 속성 쓰기가 해당 행을 대상으로** 한다.
> 행 컴포넌트 안 위젯에 값을 넣는 방식이 이것이다.

### 페이지 `targetAlert`

```js
function onStart() {
  btnPlus.onClick = openAddDialog;
  render();
}

// 데이터 연동이 없으므로 폼 로컬 변수 하나면 충분하다.
function alerts() {
  return $form.getVar("alerts") || [];
}

function openAddDialog() {
  $form.openDialog("targetAlertAdd", null, { barrierDismissible: true }, function (result) {
    if (!result) return;              // x 로 닫았거나 배경을 탭한 경우 — 아무것도 추가하지 않는다
    var list = alerts();
    list.push(result);                // { name, price, side }
    $form.setVar("alerts", list);
    render();
  });
}

function render() {
  var list = alerts();

  // 빈 상태와 목록은 둘 중 하나만 보인다. 헤더는 어느 쪽이든 그대로다.
  emptyState.setProperty("visible", list.length === 0);
  lsvAlert.setProperty("visible", list.length > 0);

  lsvAlert.clear();
  for (var i = 0; i < list.length; i++) {
    lsvAlert.add();
    lsvAlert.current = i;             // 이 뒤의 쓰기는 i 번째 행으로 간다
    txtName.setText(list[i].name);
    txtPrice.setText(thousands(list[i].price));
    // 목표가 색이 매도/매수 구분이다. 매수 = 빨강, 매도 = 파랑.
    txtPrice.setStyleProperty("Text", "style.color",
      list[i].side === "buy" ? "#FF5B5B" : "#4D9BEE");
  }
}

// 천 단위 구분 쉼표. 과제 1 의 `core/format.dart` 와 같은 규칙이다.
function thousands(value) {
  return String(value).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}
```

### 다이얼로그 폼 `targetAlertAdd`

```js
function onStart() {
  btnClose.onClick = function () { $form.closeDialog(null); };
  btnSell.onClick = function () { submit("sell"); };
  btnBuy.onClick = function () { submit("buy"); };
}

function submit(side) {
  var name = edtName.getText().trim();
  var price = edtPrice.getText().replace(/[^0-9]/g, "");

  // 빈 값 검증까지가 필수다. 둘 중 하나라도 비면 닫지 않는다.
  if (name === "" || price === "") return;

  $form.closeDialog({ name: name, price: Number(price), side: side });
}
```

### 스튜디오에서 확인할 것

스크립트는 문서 기준으로 맞지만 **위젯 id 와 속성 이름은 스튜디오 속성 패널에서 확인해야 한다.**

- 위젯 id 를 위 스크립트와 같은 이름(`btnPlus` · `lsvAlert` · `txtName` · `txtPrice` · `emptyState` · `edtName` · `edtPrice` · `btnClose` · `btnSell` · `btnBuy`)으로 맞추면 그대로 붙는다.
- 보임/숨김 속성이 `visible` 이 맞는지, 글자 색 경로가 `setStyleProperty("Text", "style.color", ...)` 가 맞는지는 패널에서 실제 이름을 본다.
- `+` 아이콘을 Button 이 아니라 이미지로 두면 `onClick` 대신 `onTap`.
- 색을 스크립트로 바꾸는 대신 **행 컴포넌트에 매수/매도 두 변형(variant)** 을 두는 방법도 있다. 스타일 경로를 못 찾으면 이쪽이 확실하다.

---

## 제출

- [ ] 페이지 이름이 `targetAlert` 인지 재확인
- [ ] `cloneProject/assets` 를 한 번에 압축 → `~/edenCrew/lucy/` 에 보관
- [ ] `unzip -l` 로 내용 확인
