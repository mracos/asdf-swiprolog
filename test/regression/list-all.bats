#!/usr/bin/env bats
# Regression: bin/list-all version scraping (issue #4).
#
# Contract:
#   - Lists the pre-rename `pl-*` releases, not only `swipl-*`.
#   - Still lists the current `swipl-*` releases.
#   - Devel releases come first and carry the `-devel` suffix.
#   - A `swipl-` entry is not miscounted as a bare `pl-` version (the
#     substring trap), so no phantom duplicates appear.

load ../helpers

setup() { setup_sandbox; }
teardown() { teardown_sandbox; }

@test "old pl- versions are listed" {
  run bash "$PLUGIN_DIR/bin/list-all"
  [ "$status" -eq 0 ]
  [[ "$output" == *" 5.6.50 "* || "$output" == *" 5.6.50" ]] \
    || { echo "5.6.50 missing: $output"; false; }
  [[ "$output" == *"6.6.6"* ]] \
    || { echo "6.6.6 missing: $output"; false; }
}

@test "current swipl- versions are still listed" {
  run bash "$PLUGIN_DIR/bin/list-all"
  [[ "$output" == *"9.2.0"* ]]
  [[ "$output" == *"10.0.2"* ]]
}

@test "devel versions come first with the -devel suffix" {
  run bash "$PLUGIN_DIR/bin/list-all"
  [[ "$output" == *"9.3.1-devel"* ]] \
    || { echo "devel tag missing: $output"; false; }
  # Devel block is emitted ahead of the stable block.
  [[ "${output%%9.2.0*}" == *"9.3.1-devel"* ]] \
    || { echo "devel not before stable: $output"; false; }
}

@test "no phantom versions from the swipl-/pl- substring overlap" {
  # 5 stable (2 pl + 3 swipl) + 2 devel = 7 distinct tokens, no more.
  run bash "$PLUGIN_DIR/bin/list-all"
  local count
  count="$(printf '%s\n' $output | grep -c .)"
  [ "$count" -eq 7 ] \
    || { echo "expected 7 versions, got $count: $output"; false; }
}
