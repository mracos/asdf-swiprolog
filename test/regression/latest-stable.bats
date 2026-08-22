#!/usr/bin/env bats
# Regression: bin/latest-stable and the version ordering it depends on.
#
# Contract:
#   - Versions sort numerically by major, so 10.x beats 9.x. Sorting the
#     major lexicographically put 10.0.2 before 5.6.50 and handed
#     `asdf latest` the wrong version.
#   - latest-stable never returns a -devel release, however new it is.
#   - An optional query narrows the result to a version prefix.
#
# Fixture versions: stable 5.6.50, 6.6.6, 7.2.0, 9.2.0, 10.0.2;
# devel 9.3.1, 9.3.2.

load ../helpers

setup() { setup_sandbox; }
teardown() { teardown_sandbox; }

latest_stable() { run bash "$PLUGIN_DIR/bin/latest-stable" ${1+"$1"}; }

@test "stable versions are ordered numerically by major" {
  run bash "$PLUGIN_DIR/bin/list-all"
  [ "$status" -eq 0 ]
  [[ "$output" == *"9.2.0 10.0.2" ]] \
    || { echo "10.x should sort last: $output"; false; }
}

@test "devel versions are ordered numerically too" {
  run bash "$PLUGIN_DIR/bin/list-all"
  [[ "$output" == "9.3.1-devel 9.3.2-devel "* ]] \
    || { echo "devel block misordered: $output"; false; }
}

@test "latest-stable returns the newest stable release" {
  latest_stable
  [ "$status" -eq 0 ]
  [ "$output" = "10.0.2" ] \
    || { echo "expected 10.0.2, got: $output"; false; }
}

@test "latest-stable never returns a devel release" {
  latest_stable
  [[ "$output" != *"-devel"* ]] \
    || { echo "devel leaked into latest: $output"; false; }
}

@test "a query narrows to that major" {
  latest_stable 9
  [ "$output" = "9.2.0" ] \
    || { echo "expected 9.2.0, got: $output"; false; }
}

@test "a query can be a full prefix" {
  latest_stable 6.6
  [ "$output" = "6.6.6" ] \
    || { echo "expected 6.6.6, got: $output"; false; }
}

@test "the query is matched literally, not as a regex" {
  # '9.2' must not match via '.' as any-character, and must anchor at the
  # start so '0.2' cannot match 10.0.2.
  latest_stable 0.2
  [ -z "$output" ] \
    || { echo "unanchored match: $output"; false; }
}

@test "an unmatched query prints nothing" {
  latest_stable 3
  [ -z "$output" ] \
    || { echo "unexpected output: $output"; false; }
}
