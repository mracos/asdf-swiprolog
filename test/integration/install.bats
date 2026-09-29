#!/usr/bin/env bats
# Integration: a real `mise install swiprolog@<version>` end to end (download,
# cmake, make, make install). Slow, needs a network and a build toolchain, so
# it is skipped unless ASDF_SWIPROLOG_RUN_INTEGRATION=1. Run locally with:
#
#   ASDF_SWIPROLOG_RUN_INTEGRATION=1 npm run test:integration
#
# The regression suite stubs curl/cmake/make against fixture snapshots, so it
# stays green even when the download page changes shape or the newest release
# stops compiling. This suite is the only thing that talks to swi-prolog.org
# for real, which is why CI runs it on a schedule: the version under test is
# resolved live rather than pinned.

setup_file() {
    [[ "${ASDF_SWIPROLOG_RUN_INTEGRATION:-0}" == "1" ]] \
        || skip "set ASDF_SWIPROLOG_RUN_INTEGRATION=1 to run integration tests"

    PLUGIN_DIR="$(cd -- "$(dirname -- "$BATS_TEST_FILENAME")/../.." && pwd)"
    export PLUGIN_DIR

    # Deliberately not pinned: the point of the scheduled run is to find out
    # that today's newest stable release no longer builds.
    SWIPL_VERSION="$("$PLUGIN_DIR/bin/latest-stable")"
    export SWIPL_VERSION

    mise plugin uninstall swiprolog >/dev/null 2>&1 || true
    mise plugin link swiprolog "$PLUGIN_DIR" >&2
}

teardown_file() {
    [[ "${ASDF_SWIPROLOG_RUN_INTEGRATION:-0}" == "1" ]] || return 0
    mise uninstall -y "swiprolog@$SWIPL_VERSION" >/dev/null 2>&1 || true
}

@test "list-all reaches both live download pages" {
    run bash "$PLUGIN_DIR/bin/list-all"
    [ "$status" -eq 0 ]
    [ -n "$output" ] || { echo "list-all returned nothing"; false; }
    # Devel entries only appear if the second page scraped too, and the suffix
    # only appears if the version regex still matched something.
    [[ "$output" == *"-devel"* ]] \
        || { echo "no devel entries: $output"; false; }
}

@test "latest-stable resolves to a version number" {
    [[ "$SWIPL_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] \
        || { echo "latest-stable returned '$SWIPL_VERSION'"; false; }
}

@test "ls-remote serves the resolved version through mise" {
    run mise ls-remote swiprolog
    [ "$status" -eq 0 ]
    [[ "$output" == *"$SWIPL_VERSION"* ]] \
        || { echo "$SWIPL_VERSION missing from ls-remote"; false; }
}

@test "installs the latest stable release and swipl reports its version" {
    mise install "swiprolog@$SWIPL_VERSION" >&2

    run mise exec "swiprolog@$SWIPL_VERSION" -- swipl --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"SWI-Prolog"* ]]
    [[ "$output" == *"$SWIPL_VERSION"* ]]
}

@test "the installed swipl evaluates a goal" {
    run mise exec "swiprolog@$SWIPL_VERSION" -- \
        swipl -g 'X is 21*2, write(X), nl, halt' -t 'halt(1)'
    [ "$status" -eq 0 ]
    [[ "$output" == *"42"* ]]
}
