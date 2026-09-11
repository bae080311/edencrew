# 화면 · 토큰 · 기기 레이아웃

화면이나 위젯을 만들기 전에 읽는다.

## 토큰

`context.colors.*` / `context.dimens.*` / `AppTypography.*` 만 쓴다(`critical.md` 1~2번). 폰트 크기는 토큰에 없으니 Figma 텍스트 레이어 값을 그대로 쓴다.

토큰 이름과 Figma 변수의 대응표는 `app/lib/theme/README.md` 에 있다. 화면에 필요한 토큰이 없으면 **값을 고치지 말고 추가**하고, 추가한 이유를 `README.md` 에 남긴다.

## 기기 레이아웃

**393 × 852 는 Figma 값의 기준 프레임이지 캔버스 크기가 아니다.** 고정값으로 쓰는 건 여백 · 폰트 크기 · 아이콘 크기뿐이고, 화면을 채우는 폭 · 높이는 고정하지 않는다.

- `width: 393` · `SizedBox(width: 350)` 로 화면을 채우지 않는다 → `Expanded` / `Flexible` / `double.infinity`.
- 종목명은 `Flexible` + `TextOverflow.ellipsis` 1줄, 가격 영역 폭을 우선 확보한다.
- `SafeArea` + 세로 스크롤. 852 보다 짧은 기기에서 잘리면 안 된다.
- 시스템 글자 확대는 **`textScaler` 1.3 까지 오버플로 없이** 견딘다. 행 높이가 늘어나는 건 허용.
- 확인 대상 3종: **375×667(SE) · 393×852(기준) · 430×932(Pro Max)**. 태블릿 · 가로 모드는 대상이 아니다.
