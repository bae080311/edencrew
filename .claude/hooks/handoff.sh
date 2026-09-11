#!/bin/bash
# git push 직후 .claude/HANDOFF.md 를 갱신하고(write), 세션 시작 때 읽어준다(read).
# Claude Code 훅은 stdin 으로 JSON 을 준다. Codex 는 인자만 주고 stdin 을 비운다.
set -uo pipefail

mode="${1:-read}"
root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
out="$root/.claude/HANDOFF.md"
flow="$root/.claude/plan/flow.md"

# 날짜가 아니라 "미완료 항목이 남은 첫 Phase" 를 현재 Phase 로 본다. 일정이 밀려도 맞는다.
flow_todo() {
  [ -f "$flow" ] || return 0
  awk '/^## Phase/{if(p)exit; sec=$0; shown=0} /^- \[ \]/{if(!shown){print sec; shown=1; p=1} print}' "$flow" | head -12
}

if [ "$mode" = read ]; then
  if [ -s "$out" ]; then
    cat "$out"
  else
    printf '# 오늘 할 일 (.claude/plan/flow.md 첫 미완료 Phase)\n\n'
    flow_todo
  fi
  exit 0
fi

# write — 훅으로 불렸으면 git push 일 때만 돈다. 인자로 직접 부르면 stdin 이 비어 그대로 통과한다.
if [ ! -t 0 ]; then
  input=$(cat)
  if [ -n "$input" ]; then
    name=$(printf '%s' "$input" | /usr/bin/jq -r '.tool_name // empty' 2>/dev/null)
    cmd=$(printf '%s' "$input" | /usr/bin/jq -r '.tool_input.command // empty' 2>/dev/null)
    [ "$name" = "Bash" ] || exit 0
    # 문자열이 아니라 실제 호출만 잡는다(문서에 적힌 단어에 반응하면 안 된다).
    printf '%s' "$cmd" | grep -Eq '(^|[;&|(]|&&)[[:space:]]*git[[:space:]]+push' || exit 0
  fi
fi

cd "$root" || exit 0

or_none() { [ -n "$1" ] && printf '%s\n' "$1" || printf '없음\n'; }

branch=$(git branch --show-current 2>/dev/null)
commits=$(git log --oneline -5 2>/dev/null)
dirty=$(git status --short 2>/dev/null)
unpushed=$(git log '@{u}..HEAD' --oneline 2>/dev/null)
todo1=$(grep -c '^- \[ \]' "$root/.claude/plan/flutter-app.md" 2>/dev/null)
todo2=$(grep -c '^- \[ \]' "$root/.claude/plan/lucy-target-alert.md" 2>/dev/null)

{
  printf '# 핸드오프 — %s (git push 직후 자동 생성)\n\n' "$(date '+%Y-%m-%d %H:%M')"
  printf '## 사실\n\n'
  printf '브랜치: %s\n\n' "${branch:-?}"
  printf '최근 커밋\n```\n%s\n```\n\n' "$(or_none "$commits")"
  printf '미커밋 변경\n```\n%s\n```\n\n' "$(or_none "$dirty")"
  printf '미푸시 커밋\n```\n%s\n```\n\n' "$(or_none "$unpushed")"
  printf '체크리스트 미완료 — 과제1 %s건 · 과제2 %s건\n\n' "${todo1:-?}" "${todo2:-?}"
  printf '현재 Phase 남은 것 (.claude/plan/flow.md)\n```\n%s\n```\n\n' "$(flow_todo)"
  printf '## 메모\n\n'
  printf -- '- 막힌 곳 : \n'
  printf -- '- 다음 첫 작업 : \n'
} > "$out"

printf '%s 의 "## 사실" 을 갱신했다. "## 메모" 의 두 줄(막힌 곳 / 다음 첫 작업)을 이번 세션 내용으로 채워라. "## 사실" 은 건드리지 않는다.\n' "${out#"$root"/}" >&2
exit 2
