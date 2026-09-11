#!/bin/bash
# Write/Edit 직후 .dart 파일을 포맷하고 아키텍처 규칙을 grep 으로 검사한다.
# 위반은 경고만 한다(exit 2 -> stderr 가 Claude 에게 전달). 편집 자체를 막지는 않는다.
set -uo pipefail

# 훅으로 불리면 stdin 에 JSON, Codex 등에서 직접 부르면 인자로 파일 경로를 받는다.
input=""
[ -t 0 ] || input=$(cat)
file=$(printf '%s' "$input" | /usr/bin/jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -n "$file" ] || file="${1:-}"

[ -n "$file" ] || exit 0
case "$file" in *.dart) ;; *) exit 0 ;; esac
[ -f "$file" ] || exit 0

# flutter 미설치 구간에서도 무해하게 넘어간다
if command -v dart >/dev/null 2>&1; then
  dart format "$file" >/dev/null 2>&1 || true
fi

warn=""
add() { warn="${warn}
- $1"; }
hits() { grep -nE "$1" "$file" 2>/dev/null | head -3; }

# main 에서 코드를 고치고 있으면 먼저 브랜치부터 판다
branch=$(git -C "$(dirname "$file")" branch --show-current 2>/dev/null)
[ "$branch" = "main" ] && add "main 에서 작업 중이다. 커밋 전에 새 브랜치를 판다: git switch -c feat/<내용> (.claude/rules/conventions.md 브랜치 절)"

is_theme=0
case "$file" in */lib/theme/*) is_theme=1 ;; esac

if [ "$is_theme" = 1 ]; then
  add "lib/theme/ 는 Figma 변수와 1:1 로 대응하는 스타터 토큰이다. 값을 수정하지 말 것. 토큰을 추가했다면 이유를 README.md 에 남긴다."
else
  h=$(hits 'Color\(0x|Colors\.|app_palette|AppPalette')
  [ -n "$h" ] && add "색을 직접 쓰지 말고 context.colors.* 를 쓴다:
$h"
fi

case "$file" in
  */lib/ui/*)
    h=$(hits "import[^;]*(data/dto/|data/source/|naver_stock_repository|fake_stock_repository)")
    [ -n "$h" ] && add "ui 레이어는 추상 StockRepository 만 참조한다. dto/source/구체 repository import 금지:
$h"
    ;;
esac

case "$file" in
  */lib/data/*)
    h=$(hits "import[^;]*package:flutter/")
    [ -n "$h" ] && add "data 레이어는 순수 Dart 로 유지한다. flutter 의존 금지:
$h"
    ;;
esac

case "$file" in
  *_view.dart)
    h=$(hits '\.sort\(|toStringAsFixed|NumberFormat|DateTime\.parse|package:http')
    [ -n "$h" ] && add "View 는 비즈니스 계산을 하지 않는다. 정렬·포맷·파싱은 ViewModel 또는 core/format.dart 로:
$h"
    h=$(hits 'width:[[:space:]]*393|height:[[:space:]]*852')
    [ -n "$h" ] && add "393×852 는 Figma 기준 프레임이지 캔버스 크기가 아니다. 화면을 채우는 폭·높이는 Expanded/Flexible/double.infinity 로:
$h"
    ;;
esac

case "$file" in
  *_ui_model.dart)
    h=$(hits '\bColor\b|TextStyle')
    [ -n "$h" ] && add "UI 모델에 Flutter 표현 객체를 담지 않는다. 의미 enum(PriceTone 등)으로 넘기고 View 에서 context.colors 로 매핑:
$h"
    ;;
esac

[ -z "$warn" ] && exit 0

printf '규칙 위반 (%s):%s\n\n근거는 .claude/rules/ 의 해당 파일에 있다.\n' "${file##*/}" "$warn" >&2
exit 2
