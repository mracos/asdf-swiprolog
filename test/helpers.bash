#!/usr/bin/env bash
# Shared bats helpers for asdf-swiprolog tests.
#
# The install/list-all scripts talk to the network (curl) and the build
# toolchain (cmake, make, tar). These helpers stand up a sandbox with a
# stub bin dir on a minimal PATH so the *real* scripts run end to end while
# every external command is a recording stub. No network, no compiler.

# Repo root, computed from this file's location.
export PLUGIN_DIR="${PLUGIN_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
export FIXTURES_DIR="$PLUGIN_DIR/test/fixtures"

# Build a per-test sandbox: a stub bin dir plus the record files the stubs
# write to. PATH is pinned to the stubs + system bins only, so brew/port
# (which live in /opt/homebrew, /usr/local, /opt/local) are invisible
# unless a test stubs them explicitly. Call from setup().
setup_sandbox() {
  WORK_DIR="$(mktemp -dt asdf-swiprolog-test-XXXXXX)"
  export WORK_DIR
  export STUB_BIN="$WORK_DIR/bin"
  export CURL_URL_LOG="$WORK_DIR/curl-url.log"
  export CMAKE_ARGS_LOG="$WORK_DIR/cmake-args.log"
  export CONFIGURE_ARGS_LOG="$WORK_DIR/configure-args.log"
  export MAKE_ARGS_LOG="$WORK_DIR/make-args.log"
  mkdir -p "$STUB_BIN"
  : > "$CURL_URL_LOG"
  : > "$MAKE_ARGS_LOG"

  # mktemp is stubbed rather than sandboxed via TMPDIR: BSD mktemp -t
  # ignores TMPDIR (it uses _CS_DARWIN_USER_TEMP_DIR) while GNU mktemp
  # honours it, so a TMPDIR-based assertion would pass vacuously on macOS.
  # The stub hands out a known dir under $SCRATCH_ROOT instead, so tests
  # can assert the installer removes what it was given.
  export SCRATCH_ROOT="$WORK_DIR/scratch"
  mkdir -p "$SCRATCH_ROOT"

  cat > "$STUB_BIN/mktemp" <<'STUB'
#!/usr/bin/env bash
dir="$SCRATCH_ROOT/build.$$"
mkdir -p "$dir"
echo "$dir"
STUB

  # curl serves two shapes:
  #   download mode  (`-Lo file url`) -> log the url, create the file
  #   fetch mode     (`-s url`)       -> print the matching index fixture
  cat > "$STUB_BIN/curl" <<'STUB'
#!/usr/bin/env bash
args=("$@"); out=""; i=0
while [ $i -lt ${#args[@]} ]; do
  case "${args[$i]}" in
    -*o) i=$((i+1)); out="${args[$i]}" ;;   # -o, -Lo, -fLo, ...
  esac
  i=$((i+1))
done
url="${args[${#args[@]}-1]}"
echo "$url" >> "$CURL_URL_LOG"
# CURL_FAIL simulates a 404. Real curl only reports that as an error when
# asked with -f; otherwise it writes the error page to the output file and
# still exits 0, which is what makes an unguarded download dangerous.
if [ -n "${CURL_FAIL:-}" ]; then
  if [[ " $* " == *" -f"* ]]; then
    echo "curl: (22) The requested URL returned error: 404" >&2
    exit 22
  fi
  [ -n "$out" ] && echo "<html>404 Not Found</html>" > "$out"
  exit 0
fi
if [ -n "$out" ]; then
  : > "$out"
  exit 0
fi
case "$url" in
  *devel*) cat "$FIXTURES_DIR/devel-src-index.html" ;;
  *)       cat "$FIXTURES_DIR/stable-src-index.html" ;;
esac
STUB

  # cmake / configure record their argv so tests can assert on flags.
  cat > "$STUB_BIN/cmake" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$@" >> "$CMAKE_ARGS_LOG"
STUB

  # tar is a no-op; the build never really runs. make records its argv so
  # tests can assert on the concurrency flag.
  printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_BIN/tar"
  cat > "$STUB_BIN/make" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$MAKE_ARGS_LOG"
STUB

  # Default host is Linux so the macOS branch stays dormant unless a test
  # opts in via stub_uname Darwin.
  stub_uname Linux

  chmod +x "$STUB_BIN"/*
  export PATH="$STUB_BIN:/usr/bin:/bin:/usr/sbin:/sbin"
}

teardown_sandbox() {
  [[ -n "${WORK_DIR:-}" && -d "$WORK_DIR" ]] && rm -rf "$WORK_DIR"
}

# stub_uname <value> — make `uname` report the given kernel.
stub_uname() {
  printf '#!/usr/bin/env bash\necho %q\n' "$1" > "$STUB_BIN/uname"
  chmod +x "$STUB_BIN/uname"
}

# stub_present <name> — put a trivial exit-0 command on PATH (e.g. brew, port).
stub_present() {
  printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_BIN/$1"
  chmod +x "$STUB_BIN/$1"
}

# run_install <version> — run the real bin/install against a sandboxed
# install path. Seeds a ./configure stub so the autoconf branch (old
# versions) also completes cleanly. Populates $output/$status via bats.
run_install() {
  export ASDF_INSTALL_TYPE=version
  export ASDF_INSTALL_VERSION="$1"
  export ASDF_INSTALL_PATH="$WORK_DIR/install"
  mkdir -p "$ASDF_INSTALL_PATH"
  cat > "$ASDF_INSTALL_PATH/configure" <<'CFG'
#!/usr/bin/env bash
printf '%s\n' "$@" >> "$CONFIGURE_ARGS_LOG"
CFG
  chmod +x "$ASDF_INSTALL_PATH/configure"
  run bash "$PLUGIN_DIR/bin/install"
}
