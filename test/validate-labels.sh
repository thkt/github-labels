#!/usr/bin/env bash
# T-001 (FR-001): labels.yml が yq parse 可能で、必須要素が揃っているか検証
# T-011 (FR-101): labels.yml に invalid YAML が混入した場合に検出可能か（test fixture で別途確認）
set -euo pipefail

LABELS_YML="$(dirname "$0")/../labels.yml"
EXIT_CODE=0

fail() {
  echo "FAIL: $1" >&2
  EXIT_CODE=1
}

pass() {
  echo "PASS: $1"
}

# T-001-1: yq parse 成功 (root が array であること)
if ! yq -e '. | type == "!!seq"' "$LABELS_YML" >/dev/null 2>&1; then
  fail "T-001-1: labels.yml の root が array でない (github-label-sync は root list 形式必須)"
else
  pass "T-001-1: labels.yml yq parse 成功 (root array)"
fi

# T-001-2: GitHub標準9個が含まれる
REQUIRED_DEFAULTS=(bug documentation duplicate enhancement "good first issue" "help wanted" invalid question wontfix)
LOCAL_FAILED=0
for label in "${REQUIRED_DEFAULTS[@]}"; do
  if ! yq -e ".[] | select(.name == \"$label\")" "$LABELS_YML" >/dev/null 2>&1; then
    fail "T-001-2: 標準ラベル '$label' が無い"
    LOCAL_FAILED=1
  fi
done
[[ $LOCAL_FAILED -eq 0 ]] && pass "T-001-2: GitHub標準9個 検証完了"

# T-001-3: priority:* 3個が含まれる（high, medium, low）
LOCAL_FAILED=0
for prio in high medium low; do
  if ! yq -e ".[] | select(.name == \"priority:$prio\")" "$LABELS_YML" >/dev/null 2>&1; then
    fail "T-001-3: priority:$prio が無い"
    LOCAL_FAILED=1
  fi
done
[[ $LOCAL_FAILED -eq 0 ]] && pass "T-001-3: priority:* 3個 検証完了"

# T-001-4: preserve list（dependencies, ci, rust）が labels.yml に明示
LOCAL_FAILED=0
for label in dependencies ci rust; do
  if ! yq -e ".[] | select(.name == \"$label\")" "$LABELS_YML" >/dev/null 2>&1; then
    fail "T-001-4: preserve list の '$label' が無い"
    LOCAL_FAILED=1
  fi
done
[[ $LOCAL_FAILED -eq 0 ]] && pass "T-001-4: preserve list 3個 検証完了"

# FR-014: 色規律 priority:* は graduated red→orange→yellow
PRIORITY_HIGH_COLOR=$(yq -r '.[] | select(.name == "priority:high") | .color' "$LABELS_YML")
PRIORITY_MEDIUM_COLOR=$(yq -r '.[] | select(.name == "priority:medium") | .color' "$LABELS_YML")
PRIORITY_LOW_COLOR=$(yq -r '.[] | select(.name == "priority:low") | .color' "$LABELS_YML")

# 期待値: high=red系 (B60205), medium=orange系 (E4A607), low=yellow/green系 (0E8A16 or yellow)
if [[ "$PRIORITY_HIGH_COLOR" != "B60205" ]]; then
  fail "FR-014: priority:high color expected B60205, got $PRIORITY_HIGH_COLOR"
fi
if [[ "$PRIORITY_MEDIUM_COLOR" != "E4A607" ]]; then
  fail "FR-014: priority:medium color expected E4A607, got $PRIORITY_MEDIUM_COLOR"
fi
if [[ "$PRIORITY_LOW_COLOR" != "0E8A16" ]]; then
  fail "FR-014: priority:low color expected 0E8A16, got $PRIORITY_LOW_COLOR"
fi
pass "FR-014: priority:* graduated color 検証完了"

# T-001-5: 全ラベルに description がある
LABELS_WITHOUT_DESC=$(yq -r '.[] | select(.description == null or .description == "") | .name' "$LABELS_YML")
if [[ -n "$LABELS_WITHOUT_DESC" ]]; then
  fail "T-001-5: description 欠落のラベル: $LABELS_WITHOUT_DESC"
else
  pass "T-001-5: 全ラベルに description あり"
fi

# T-006 (FR-008): yomu の P1/P2/P3 が aliases に登録されている (alias migration 準備)
LOCAL_FAILED=0
ALIAS_PAIRS=(
  "P1|priority:high"
  "P2|priority:medium"
  "P3|priority:low"
)
for pair in "${ALIAS_PAIRS[@]}"; do
  old_name="${pair%%|*}"
  canonical="${pair#*|}"
  if ! yq -e ".[] | select(.name == \"$canonical\") | .aliases[] | select(. == \"$old_name\")" "$LABELS_YML" >/dev/null 2>&1; then
    fail "T-006: '$old_name' が '$canonical' の aliases に無い"
    LOCAL_FAILED=1
  fi
done
[[ $LOCAL_FAILED -eq 0 ]] && pass "T-006: P1/P2/P3 → priority:* aliases 検証完了"

# T-007 (FR-004): target_repos.txt が valid (全行 thkt/ で始まる、重複なし)
TARGET_REPOS="$(dirname "$0")/../target_repos.txt"
if [[ -f "$TARGET_REPOS" ]]; then
  LOCAL_FAILED=0
  INVALID_LINES=$(grep -v '^[[:space:]]*$' "$TARGET_REPOS" | grep -v '^#' | grep -v '^thkt/' || true)
  if [[ -n "$INVALID_LINES" ]]; then
    fail "T-007: target_repos.txt に thkt/ で始まらない行: $INVALID_LINES"
    LOCAL_FAILED=1
  fi
  DUP=$(grep -v '^[[:space:]]*$' "$TARGET_REPOS" | grep -v '^#' | sort | uniq -d || true)
  if [[ -n "$DUP" ]]; then
    fail "T-007: target_repos.txt に重複: $DUP"
    LOCAL_FAILED=1
  fi
  COUNT=$(grep -v '^[[:space:]]*$' "$TARGET_REPOS" | grep -v '^#' | wc -l | tr -d ' ')
  if [[ "$COUNT" -lt 20 ]]; then
    fail "T-007: target_repos.txt repo数が少ない ($COUNT < 20)"
    LOCAL_FAILED=1
  fi
  [[ $LOCAL_FAILED -eq 0 ]] && pass "T-007: target_repos.txt 検証完了 ($COUNT repos)"
else
  echo "INFO: target_repos.txt 未配備、検証スキップ"
fi

if [[ $EXIT_CODE -eq 0 ]]; then
  echo ""
  echo "ALL TESTS PASSED"
else
  echo ""
  echo "SOME TESTS FAILED"
fi

exit $EXIT_CODE
