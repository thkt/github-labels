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

# T-001-1: yq parse 成功
if ! yq '.labels' "$LABELS_YML" >/dev/null 2>&1; then
  fail "T-001-1: labels.yml が yq で parse 不可"
else
  pass "T-001-1: labels.yml yq parse 成功"
fi

# T-001-2: GitHub標準9個が含まれる
REQUIRED_DEFAULTS=(bug documentation duplicate enhancement "good first issue" "help wanted" invalid question wontfix)
LOCAL_FAILED=0
for label in "${REQUIRED_DEFAULTS[@]}"; do
  if ! yq -e ".labels[] | select(.name == \"$label\")" "$LABELS_YML" >/dev/null 2>&1; then
    fail "T-001-2: 標準ラベル '$label' が無い"
    LOCAL_FAILED=1
  fi
done
[[ $LOCAL_FAILED -eq 0 ]] && pass "T-001-2: GitHub標準9個 検証完了"

# T-001-3: priority:* 3個が含まれる（high, medium, low）
LOCAL_FAILED=0
for prio in high medium low; do
  if ! yq -e ".labels[] | select(.name == \"priority:$prio\")" "$LABELS_YML" >/dev/null 2>&1; then
    fail "T-001-3: priority:$prio が無い"
    LOCAL_FAILED=1
  fi
done
[[ $LOCAL_FAILED -eq 0 ]] && pass "T-001-3: priority:* 3個 検証完了"

# T-001-4: preserve list（dependencies, ci, rust）が labels.yml に明示
LOCAL_FAILED=0
for label in dependencies ci rust; do
  if ! yq -e ".labels[] | select(.name == \"$label\")" "$LABELS_YML" >/dev/null 2>&1; then
    fail "T-001-4: preserve list の '$label' が無い"
    LOCAL_FAILED=1
  fi
done
[[ $LOCAL_FAILED -eq 0 ]] && pass "T-001-4: preserve list 3個 検証完了"

# FR-014: 色規律 priority:* は graduated red→orange→yellow
PRIORITY_HIGH_COLOR=$(yq -r '.labels[] | select(.name == "priority:high") | .color' "$LABELS_YML")
PRIORITY_MEDIUM_COLOR=$(yq -r '.labels[] | select(.name == "priority:medium") | .color' "$LABELS_YML")
PRIORITY_LOW_COLOR=$(yq -r '.labels[] | select(.name == "priority:low") | .color' "$LABELS_YML")

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
LABELS_WITHOUT_DESC=$(yq -r '.labels[] | select(.description == null or .description == "") | .name' "$LABELS_YML")
if [[ -n "$LABELS_WITHOUT_DESC" ]]; then
  fail "T-001-5: description 欠落のラベル: $LABELS_WITHOUT_DESC"
else
  pass "T-001-5: 全ラベルに description あり"
fi

if [[ $EXIT_CODE -eq 0 ]]; then
  echo ""
  echo "ALL TESTS PASSED"
else
  echo ""
  echo "SOME TESTS FAILED"
fi

exit $EXIT_CODE
