#!/usr/bin/env bats
# Regression: bin/install failure and housekeeping behaviour.
#
# Contract:
#   - Sources are fetched over https, not plaintext http.
#   - A failed download aborts the install with a readable message,
#     instead of handing a 404 page to tar.
#   - The build honours ASDF_CONCURRENCY (asdf and mise both set it).
#   - The scratch download dir is removed, success or failure.

load ../helpers

setup() { setup_sandbox; }
teardown() { teardown_sandbox; }

scratch_dirs() { ls -A "$SCRATCH_ROOT" 2>/dev/null || true; }

@test "stable downloads use https" {
  run_install 9.2.0
  [ "$status" -eq 0 ]
  run cat "$CURL_URL_LOG"
  [[ "$output" == "https://"* ]] \
    || { echo "not https: $output"; false; }
}

@test "devel downloads use https" {
  run_install 9.3.1-devel
  [ "$status" -eq 0 ]
  run cat "$CURL_URL_LOG"
  [[ "$output" == "https://"* ]] \
    || { echo "not https: $output"; false; }
}

@test "pre-rename downloads use https" {
  run_install 6.6.6
  [ "$status" -eq 0 ]
  run cat "$CURL_URL_LOG"
  [[ "$output" == "https://"* ]] \
    || { echo "not https: $output"; false; }
}

@test "a failed download aborts the install" {
  export CURL_FAIL=1
  run_install 9.2.0
  [ "$status" -ne 0 ] \
    || { echo "install reported success after a failed download"; false; }
}

@test "a failed download never reaches the build" {
  export CURL_FAIL=1
  run_install 9.2.0
  [ ! -s "$MAKE_ARGS_LOG" ] \
    || { echo "make ran anyway: $(cat "$MAKE_ARGS_LOG")"; false; }
  [ ! -s "$CMAKE_ARGS_LOG" ] \
    || { echo "cmake ran anyway: $(cat "$CMAKE_ARGS_LOG")"; false; }
}

@test "a failed download names the url it could not fetch" {
  export CURL_FAIL=1
  run_install 9.2.0
  [[ "$output" == *"swipl-9.2.0.tar.gz"* ]] \
    || { echo "unhelpful failure output: $output"; false; }
}

@test "ASDF_CONCURRENCY is passed to make" {
  export ASDF_CONCURRENCY=7
  run_install 9.2.0
  [ "$status" -eq 0 ]
  run cat "$MAKE_ARGS_LOG"
  [[ "$output" == *"-j7"* || "$output" == *"-j 7"* ]] \
    || { echo "concurrency not honoured: $output"; false; }
}

@test "unset ASDF_CONCURRENCY still builds" {
  run_install 9.2.0
  [ "$status" -eq 0 ]
  run cat "$MAKE_ARGS_LOG"
  [ -n "$output" ] || { echo "make never ran"; false; }
}

@test "the install step is not parallelised" {
  export ASDF_CONCURRENCY=7
  run_install 9.2.0
  [ "$status" -eq 0 ]
  run grep -c 'install' "$MAKE_ARGS_LOG"
  [ "$output" -eq 1 ] || { echo "unexpected install invocations: $output"; false; }
  run grep 'install' "$MAKE_ARGS_LOG"
  [[ "$output" != *"-j"* ]] \
    || { echo "make install should stay serial: $output"; false; }
}

@test "the scratch download dir is removed on success" {
  run_install 9.2.0
  [ "$status" -eq 0 ]
  run scratch_dirs
  [ -z "$output" ] || { echo "leaked scratch dir: $output"; false; }
}

@test "the scratch download dir is removed after a failed download" {
  export CURL_FAIL=1
  run_install 9.2.0
  run scratch_dirs
  [ -z "$output" ] || { echo "leaked scratch dir: $output"; false; }
}

@test "the scratch download dir is removed after a failed build" {
  printf '#!/usr/bin/env bash\nexit 1\n' > "$STUB_BIN/make"
  chmod +x "$STUB_BIN/make"
  run_install 9.2.0
  [ "$status" -ne 0 ]
  run scratch_dirs
  [ -z "$output" ] || { echo "leaked scratch dir: $output"; false; }
}
