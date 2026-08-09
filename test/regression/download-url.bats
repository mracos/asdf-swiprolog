#!/usr/bin/env bats
# Regression: bin/install download URL selection.
#
# Contract:
#   - Versions before the swipl rename (< 7.0) download `pl-*` tarballs.
#   - Versions >= 7.0 download `swipl-*` tarballs.
#   - The `-devel` suffix routes to the devel channel and is stripped
#     from the tarball name, while keeping the version-based prefix.
#
# The `pl-*` cases guard issue #4: listing old versions is useless if the
# installer then reaches for a `swipl-<old>.tar.gz` that 404s.

load ../helpers

setup() { setup_sandbox; }
teardown() { teardown_sandbox; }

@test "pre-rename version downloads the pl- tarball" {
  run_install 5.6.50
  [ "$status" -eq 0 ]
  run cat "$CURL_URL_LOG"
  [[ "$output" == *"/stable/src/pl-5.6.50.tar.gz" ]] \
    || { echo "unexpected url: $output"; false; }
}

@test "last pre-rename version (6.6.6) still uses pl-" {
  run_install 6.6.6
  [ "$status" -eq 0 ]
  run cat "$CURL_URL_LOG"
  [[ "$output" == *"/stable/src/pl-6.6.6.tar.gz" ]]
}

@test "7.0.0 and up use the swipl- tarball" {
  run_install 7.2.0
  [ "$status" -eq 0 ]
  run cat "$CURL_URL_LOG"
  [[ "$output" == *"/stable/src/swipl-7.2.0.tar.gz" ]] \
    || { echo "unexpected url: $output"; false; }
}

@test "modern version uses the swipl- tarball" {
  run_install 9.2.0
  [ "$status" -eq 0 ]
  run cat "$CURL_URL_LOG"
  [[ "$output" == *"/stable/src/swipl-9.2.0.tar.gz" ]]
}

@test "devel suffix routes to the devel channel and is stripped" {
  run_install 9.3.1-devel
  [ "$status" -eq 0 ]
  run cat "$CURL_URL_LOG"
  [[ "$output" == *"/devel/src/swipl-9.3.1.tar.gz" ]] \
    || { echo "unexpected url: $output"; false; }
}
