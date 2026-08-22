#!/usr/bin/env bats
# Regression: bin/install cmake invocation for the 7.7.21+ path.
#
# Contract:
#   - < 10: in-source build (cmake .) with -DSWIPL_PACKAGES_X=OFF.
#   - >= 10: out-of-source build (cmake ..) with -DSWIPL_PACKAGES_GUI=OFF,
#     since SWI-Prolog 10 renamed the X package option to GUI.
#   - On macOS, MACOSX_DEPENDENCIES_FROM is set from Homebrew if `brew`
#     is on PATH, else Macports if `port` is, else left unset.
#   - On non-macOS hosts no MACOSX_DEPENDENCIES_FROM flag is passed.
#   - Optional packages default to OFF. The opt-in env vars are covered
#     in package-flags.bats.

load ../helpers

setup() { setup_sandbox; }
teardown() { teardown_sandbox; }

cmake_args() { cat "$CMAKE_ARGS_LOG"; }

@test "9.x builds in-source with SWIPL_PACKAGES_X" {
  run_install 9.2.0
  [ "$status" -eq 0 ]
  run cmake_args
  [[ "$output" == *"-DSWIPL_PACKAGES_X=OFF"* ]] \
    || { echo "missing X flag: $output"; false; }
  [[ "$output" != *"SWIPL_PACKAGES_GUI"* ]] \
    || { echo "GUI flag leaked on 9.x: $output"; false; }
  [[ "$output" == *$'\n'"."$'\n'* || "$output" == "."*  ]] \
    || { echo "expected in-source '.' src dir: $output"; false; }
}

@test "10.x builds out-of-source with SWIPL_PACKAGES_GUI" {
  run_install 10.0.2
  [ "$status" -eq 0 ]
  run cmake_args
  [[ "$output" == *"-DSWIPL_PACKAGES_GUI=OFF"* ]] \
    || { echo "missing GUI flag on 10.x: $output"; false; }
  [[ "$output" != *"SWIPL_PACKAGES_X"* ]] \
    || { echo "X flag leaked on 10.x: $output"; false; }
  [[ "$output" == ".."* ]] \
    || { echo "expected out-of-source '..' src dir: $output"; false; }
}

@test "JAVA package is disabled by default" {
  run_install 9.2.0
  run cmake_args
  [[ "$output" == *"-DSWIPL_PACKAGES_JAVA=OFF"* ]]
}

@test "macOS with brew sets MACOSX_DEPENDENCIES_FROM=Homebrew" {
  stub_uname Darwin
  stub_present brew
  stub_present port
  run_install 9.2.0
  [ "$status" -eq 0 ]
  run cmake_args
  [[ "$output" == *"-DMACOSX_DEPENDENCIES_FROM=Homebrew"* ]] \
    || { echo "brew not preferred: $output"; false; }
}

@test "macOS without brew but with port sets Macports" {
  stub_uname Darwin
  stub_present port
  run_install 9.2.0
  [ "$status" -eq 0 ]
  run cmake_args
  [[ "$output" == *"-DMACOSX_DEPENDENCIES_FROM=Macports"* ]] \
    || { echo "port fallback not used: $output"; false; }
}

@test "macOS without brew or port passes no dependency flag" {
  stub_uname Darwin
  run_install 9.2.0
  [ "$status" -eq 0 ]
  run cmake_args
  [[ "$output" != *"MACOSX_DEPENDENCIES_FROM"* ]] \
    || { echo "unexpected macos dep flag: $output"; false; }
}

@test "non-macOS host passes no dependency flag" {
  run_install 9.2.0
  [ "$status" -eq 0 ]
  run cmake_args
  [[ "$output" != *"MACOSX_DEPENDENCIES_FROM"* ]]
}
