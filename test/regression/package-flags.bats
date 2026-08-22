#!/usr/bin/env bats
# Regression: optional package selection in bin/install.
#
# Contract:
#   - jpl (java) and xpce (graphics) stay off by default, as they always
#     have been.
#   - SWIPROLOG_ENABLE_JAVA / SWIPROLOG_ENABLE_GUI opt back in, on both
#     the cmake path (> 7.7.21) and the autoconf path (<= 7.7.21).
#   - Truthiness is 1/on/yes/true, case-insensitive. Anything else is off,
#     so a typo fails closed instead of silently building a package the
#     host has no toolchain for.

load ../helpers

setup() { setup_sandbox; }
teardown() { teardown_sandbox; }

cmake_args() { cat "$CMAKE_ARGS_LOG"; }
configure_args() { cat "$CONFIGURE_ARGS_LOG"; }

@test "cmake: java opt-in flips JAVA to ON" {
  export SWIPROLOG_ENABLE_JAVA=1
  run_install 9.2.0
  [ "$status" -eq 0 ]
  run cmake_args
  [[ "$output" == *"-DSWIPL_PACKAGES_JAVA=ON"* ]] \
    || { echo "java not enabled: $output"; false; }
}

@test "cmake: gui opt-in flips X to ON below 10" {
  export SWIPROLOG_ENABLE_GUI=1
  run_install 9.2.0
  [ "$status" -eq 0 ]
  run cmake_args
  [[ "$output" == *"-DSWIPL_PACKAGES_X=ON"* ]] \
    || { echo "gui not enabled: $output"; false; }
}

@test "cmake: gui opt-in flips GUI to ON on 10+" {
  export SWIPROLOG_ENABLE_GUI=1
  run_install 10.0.2
  [ "$status" -eq 0 ]
  run cmake_args
  [[ "$output" == *"-DSWIPL_PACKAGES_GUI=ON"* ]] \
    || { echo "gui not enabled: $output"; false; }
}

@test "cmake: opting into one package leaves the other off" {
  export SWIPROLOG_ENABLE_JAVA=1
  run_install 9.2.0
  [ "$status" -eq 0 ]
  run cmake_args
  [[ "$output" == *"-DSWIPL_PACKAGES_X=OFF"* ]] \
    || { echo "gui should stay off: $output"; false; }
}

@test "cmake: word-shaped truthy values are accepted" {
  export SWIPROLOG_ENABLE_JAVA=YES
  export SWIPROLOG_ENABLE_GUI=true
  run_install 9.2.0
  [ "$status" -eq 0 ]
  run cmake_args
  [[ "$output" == *"-DSWIPL_PACKAGES_JAVA=ON"* ]] \
    || { echo "YES not truthy: $output"; false; }
  [[ "$output" == *"-DSWIPL_PACKAGES_X=ON"* ]] \
    || { echo "true not truthy: $output"; false; }
}

@test "cmake: unset and falsy values keep packages off" {
  export SWIPROLOG_ENABLE_JAVA=0
  export SWIPROLOG_ENABLE_GUI=""
  run_install 9.2.0
  [ "$status" -eq 0 ]
  run cmake_args
  [[ "$output" == *"-DSWIPL_PACKAGES_JAVA=OFF"* ]] \
    || { echo "java should be off: $output"; false; }
  [[ "$output" == *"-DSWIPL_PACKAGES_X=OFF"* ]] \
    || { echo "gui should be off: $output"; false; }
}

@test "autoconf: both packages are excluded by default" {
  run_install 6.6.6
  [ "$status" -eq 0 ]
  run configure_args
  [[ "$output" == *"--without-jpl"* ]] \
    || { echo "missing --without-jpl: $output"; false; }
  [[ "$output" == *"--without-xpce"* ]] \
    || { echo "missing --without-xpce: $output"; false; }
}

@test "autoconf: java opt-in drops --without-jpl only" {
  export SWIPROLOG_ENABLE_JAVA=1
  run_install 6.6.6
  [ "$status" -eq 0 ]
  run configure_args
  [[ "$output" != *"--without-jpl"* ]] \
    || { echo "jpl still excluded: $output"; false; }
  [[ "$output" == *"--without-xpce"* ]] \
    || { echo "xpce should stay excluded: $output"; false; }
}

@test "autoconf: gui opt-in drops --without-xpce only" {
  export SWIPROLOG_ENABLE_GUI=on
  run_install 6.6.6
  [ "$status" -eq 0 ]
  run configure_args
  [[ "$output" != *"--without-xpce"* ]] \
    || { echo "xpce still excluded: $output"; false; }
  [[ "$output" == *"--without-jpl"* ]] \
    || { echo "jpl should stay excluded: $output"; false; }
}

@test "autoconf: prefix and world flags survive the opt-in" {
  export SWIPROLOG_ENABLE_JAVA=1
  run_install 6.6.6
  [ "$status" -eq 0 ]
  run configure_args
  [[ "$output" == *"--prefix=$ASDF_INSTALL_PATH"* ]] \
    || { echo "missing prefix: $output"; false; }
  [[ "$output" == *"--with-world"* ]] \
    || { echo "missing --with-world: $output"; false; }
  [[ "$output" == *"--disable-libdirversion"* ]] \
    || { echo "missing --disable-libdirversion: $output"; false; }
}
