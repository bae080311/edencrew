# lib/theme — 디자인 토큰

이 폴더는 **Figma 파일의 변수(Variables)를 그대로 옮긴 디자인 토큰**입니다.
앱 테마(`AppTheme.dark`)로 연결되어 있으니 화면 코드에서는 이 토큰만 사용해 주세요.

- 값을 임의로 수정하지 마세요. 아래 대응표로 Figma 변수와 1:1 확인이 가능합니다.
- 색상 hex를 화면 코드에 직접 쓰거나 `AppPalette`를 화면에서 바로 참조하지 마세요.
- 필요한 토큰이 없다고 판단되면 추가해도 됩니다. 다만 왜 추가했는지 메모에 적어 주세요.

## 파일 구성

| 파일 | 내용 | Figma 컬렉션 |
|---|---|---|
| `app_palette.dart` | 원시 팔레트 | `Primitives` |
| `app_colors.dart` | 시맨틱 색상 (`ThemeExtension`) | `Semantic` / Dark |
| `app_dimens.dart` | 간격 · 반경 · 크기 (`ThemeExtension`) | `Scale` |
| `app_typography.dart` | 서체 · 굵기 | `Typography` |
| `app_theme.dart` | `ThemeData` 조립 + `context` 확장 | — |
| `theme.dart` | barrel | — |

## 사용법

```dart
MaterialApp(
  theme: AppTheme.dark,
  home: const WatchlistScreen(),
)
```

```dart
Text('삼성전자', style: TextStyle(color: context.colors.textPrimary))
SizedBox(height: context.dimens.space4)
```

## 색상 대응표 (`Semantic` / Dark)

| Figma 변수 | Dart 필드 | 참조 원시값 | Hex |
|---|---|---|---|
| `surface/base` | `surfaceBase` | `neutral/950` | `#0F0F0E` |
| `surface/raised` | `surfaceRaised` | `neutral/900` | `#161614` |
| `surface/sunken` | `surfaceSunken` | `neutral/800` | `#1C1C19` |
| `surface/overlay` | `surfaceOverlay` | `neutral/700` | `#23231F` |
| `text/primary` | `textPrimary` | `neutral/0` | `#FAF9F5` |
| `text/secondary` | `textSecondary` | `neutral/200` | `#B4B2A9` |
| `text/tertiary` | `textTertiary` | `neutral/300` | `#888780` |
| `text/disabled` | `textDisabled` | `neutral/400` | `#5A5952` |
| `border/subtle` | `borderSubtle` | `neutral/700` | `#23231F` |
| `border/strong` | `borderStrong` | `neutral/500` | `#3D3D37` |
| `price/up/text` | `priceUpText` | `red/400` | `#FF5B5B` |
| `price/up/bg` | `priceUpBg` | `red/alpha-12` | `#FF5B5B` 12% |
| `price/down/text` | `priceDownText` | `blue/400` | `#4D9BEE` |
| `price/down/bg` | `priceDownBg` | `blue/alpha-12` | `#4D9BEE` 12% |
| `price/flat/text` | `priceFlatText` | `neutral/200` | `#B4B2A9` |
| `price/flat/bg` | `priceFlatBg` | `neutral/700` | `#23231F` |
| `chart/line/up` | `chartLineUp` | `red/400` | `#FF5B5B` |
| `chart/line/down` | `chartLineDown` | `blue/400` | `#4D9BEE` |
| `chart/line/flat` | `chartLineFlat` | `neutral/200` | `#B4B2A9` |
| `chart/area/up` | `chartAreaUp` | `red/alpha-12` | `#FF5B5B` 12% |
| `chart/area/down` | `chartAreaDown` | `blue/alpha-12` | `#4D9BEE` 12% |
| `chart/baseline` | `chartBaseline` | `neutral/400` | `#5A5952` |
| `chart/axis-label` | `chartAxisLabel` | `neutral/300` | `#888780` |
| `chart/volume-bar` | `chartVolumeBar` | `neutral/500` | `#3D3D37` |
| `accent/default` | `accentDefault` | `violet/500` | `#8B7CF6` |
| `accent/bg` | `accentBg` | `violet/alpha-12` | `#8B7CF6` 12% |
| `favorite/active` | `favoriteActive` | `gold/500` | `#F5B544` |
| `favorite/inactive` | `favoriteInactive` | `neutral/400` | `#5A5952` |
| `nav/active` | `navActive` | `neutral/0` | `#FAF9F5` |
| `nav/inactive` | `navInactive` | `neutral/300` | `#888780` |
| `feedback/warning` | `feedbackWarning` | `amber/500` | `#E8973A` |
| `feedback/skeleton` | `feedbackSkeleton` | `neutral/700` | `#23231F` |
| `search/highlight` | `searchHighlight` | `violet/500` | `#8B7CF6` |

`alpha-12`는 해당 색상의 12% 불투명도입니다. (`0.12 × 255 = 31 = 0x1F`)

등락 색상은 국내 시장 관행을 따릅니다. **상승은 빨강, 하락은 파랑**입니다.

## 간격 · 크기 대응표 (`Scale`)

| Figma 변수 | Dart 필드 | 값 |
|---|---|---|
| `space/1` | `space1` | 4 |
| `space/2` | `space2` | 8 |
| `space/3` | `space3` | 12 |
| `space/4` | `space4` | 16 |
| `space/5` | `space5` | 20 |
| `space/6` | `space6` | 24 |
| `radius/sm` | `radiusSm` | 4 |
| `radius/md` | `radiusMd` | 8 |
| `radius/lg` | `radiusLg` | 12 |
| `border/hairline` | `borderHairline` | 1 |
| `icon/sm` | `iconSm` | 16 |
| `icon/md` | `iconMd` | 20 |
| `size/row-min` | `rowMinHeight` | 56 |
| `size/tabbar` | `tabBarHeight` | 56 |

### 추가한 크기 — Figma 변수가 없는 값

시안에는 쓰이는데 `Scale` 컬렉션에는 변수로 올라와 있지 않은 값들입니다.
화면 코드에 숫자를 직접 적지 않도록 `AppDimens` 에 추가했고, 어느 프레임의
어느 자리에서 읽었는지 함께 적어 둡니다.

| Dart 필드 | 값 | 시안에서 읽은 곳 |
|---|---|---|
| `gapTextLine` | 2 | 목록 행 안 두 줄 사이 (종목명 ↔ 코드, 현재가 ↔ 등락) |
| `gapTabLabel` | 3 | 탭 바 아이콘 ↔ 라벨 |
| `iconTabBar` | 22 | 탭 바 아이콘 |
| `iconLg` | 24 | 정렬 바텀시트 선택 표시 |
| `iconEmpty` | 40 | 빈 상태 가운데 아이콘 |
| `iconFavorite` | 22 | 검색 결과 행의 관심 등록 버튼 |
| `iconToast` | 18 | 토스트 왼쪽 아이콘 |
| `radiusSheet` | 16 | 바텀시트 상단 모서리 |
| `sheetTitleHeight` | 64 | 바텀시트 제목 영역 높이 |

스켈레톤 막대 크기(64×16 · 48×12), 검색 입력 필드의 상하 여백 10,
토스트의 하단 간격 10 · 상하 여백 14 는 넣지 않았습니다. 간격 · 반경 · 아이콘과
달리 한 위젯의 상자 크기라서 다른 화면이 가져다 쓸 값이 아닙니다. 두 번째
사용처가 생기면 그때 올립니다.

`size/tabbar`(56)는 이 화면들에서 쓰지 않았습니다. 시안의 `Tab bar` 프레임은
여섯 화면 모두 63(상하 여백 8 + 탭 47)이라 토큰 값을 강제하면 오히려 시안과
어긋납니다.

## 서체 (`Typography`)

| Figma 변수 | Dart | 값 |
|---|---|---|
| `font/family/base` | `AppTypography.fontFamily` | `Noto Sans KR` |
| `font/style/regular` | `AppTypography.regular` | `FontWeight.w400` |
| `font/style/medium` | `AppTypography.medium` | `FontWeight.w500` |
| `font/style/bold` | `AppTypography.bold` | `FontWeight.w700` |

### 텍스트 스타일 — 추가한 토큰

크기와 행간은 Figma **Variables** 에는 없지만, **이름 붙은 텍스트 스타일**로는 정의되어 있습니다.
화면마다 크기를 따로 적으면 같은 값이 흩어지므로 그 스타일을 `TextStyle` 상수로 옮겼습니다.
값은 Figma 스타일 그대로이고 새로 지어낸 스케일이 아닙니다.

| Figma 스타일 | Dart | size / lineHeight | weight | letterSpacing |
|---|---|---|---|---|
| `display/price` | `AppTypography.displayPrice` | 30 / 36 | 700 | -0.4 |
| `title` | `AppTypography.title` | 19 / 22 | 700 | -0.2 |
| `body` | `AppTypography.body` | 15 / 20 | 500 | -0.1 |
| `label` | `AppTypography.label` | 13 / 18 | 700 | 0 |
| `caption` | `AppTypography.caption` | 11 / 14 | 400 | 0 |

Figma 에는 `body/num` · `caption/num` 도 있지만 옮기지 않았습니다.
두 스타일이 참조하는 `font/family/numeric` 이 `font/family/base` 와 **같은 `Noto Sans KR`** 이라
`body` · `caption` 과 렌더링이 완전히 같습니다. (`font/style/semibold` 의 실제 값도 `Bold`(w700)입니다.)

이 상수에는 **색을 담지 않습니다.** 화면에서 `copyWith(color: context.colors.textPrimary)` 로 입혀 주세요.
