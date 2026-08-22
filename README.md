# asdf-swiprolog

[![test](https://github.com/mracos/asdf-swiprolog/actions/workflows/test.yml/badge.svg)](https://github.com/mracos/asdf-swiprolog/actions/workflows/test.yml)

[SWI-Prolog](http://www.swi-prolog.org/) plugin for the [asdf](https://github.com/asdf-vm/asdf) and [mise](https://mise.jdx.dev/) version managers.

## Install

```sh
# asdf
asdf plugin add swiprolog https://github.com/mracos/asdf-swiprolog.git

# mise
mise plugin add swiprolog https://github.com/mracos/asdf-swiprolog.git
```

## Use

```sh
asdf list all swiprolog
asdf install swiprolog 9.2.9
asdf set swiprolog 9.2.9
```

See the [asdf](https://github.com/asdf-vm/asdf) or [mise](https://mise.jdx.dev/) docs for the full version management workflow.

## Versions

`list-all` returns the stable and devel source releases published on swi-prolog.org:

- Stable releases come as `swipl-<version>` tarballs.
- Releases before the `pl` -> `swipl` rename (older than 7.0.0) come as `pl-<version>` tarballs and are listed with their plain version number.
- Development releases are suffixed with `-devel` (for example `9.3.20-devel`) and are pulled from the devel channel.

`asdf latest swiprolog` and `mise use swiprolog@latest` resolve to the newest stable release. A `-devel` release is never picked automatically, however new it is; ask for it by name.

## Build system

The plugin picks the build system from the version:

| Version | Build |
|---------|-------|
| `<= 7.7.21` | `./configure` with `--with-world --without-jpl --without-xpce` |
| `> 7.7.21` | in-source `cmake` with `-DSWIPL_PACKAGES_X=OFF` |
| `>= 10.0.0` | out-of-source `cmake` in `build/` with `-DSWIPL_PACKAGES_GUI=OFF` |

SWI-Prolog 10 renamed the `X` package option to `GUI` and requires an out-of-source build, which is why 10+ gets its own row.

On macOS the plugin detects the dependency source and passes `-DMACOSX_DEPENDENCIES_FROM=Homebrew` or `-DMACOSX_DEPENDENCIES_FROM=Macports` depending on whether `brew` or `port` is on the PATH.

## Dependencies

Versions after `7.7.21-devel` need [cmake](https://cmake.org/), since SWI-Prolog started shipping a `CMakeLists.txt` instead of a `./configure` script.

### macOS

Install via Homebrew or MacPorts:

- `gmp`
- `jpeg`
- `libarchive`
- `libiconv`
- `libmcrypt`
- `ncurses`
- `openssl`
- `ossp-uuid`
- `pkgconfig`
- `readline`
- `zlib`
- `pcre`
- `libedit`

### Linux

See the [SWI-Prolog prerequisites](http://www.swi-prolog.org/build/prerequisites.html).

## Development

The regression suite is hermetic: `curl`, `cmake`, `make` and `tar` are replaced by recording stubs, so the real `bin/install` and `bin/list-all` run end to end with no network and no toolchain.

```sh
npm install
npm test            # bats test/regression
npm run lint:shell  # shellcheck -x -S error
```

Both run on every push and pull request via GitHub Actions. The regression leg runs on Linux and macOS, since macOS still ships bash 3.2 and the scripts have to keep working there.

## Optional packages

The `java_interface` (jpl) and the `graphics_subsystem` (xpce) are **off by default**, because both need toolchains most machines don't have (a JDK, an X/GUI stack). Two env vars turn them back on:

| Variable | Enables | Build flag |
|----------|---------|------------|
| `SWIPROLOG_ENABLE_JAVA` | jpl, the Java interface | `-DSWIPL_PACKAGES_JAVA=ON`, or no `--without-jpl` on the autoconf path |
| `SWIPROLOG_ENABLE_GUI` | xpce, the graphics subsystem | `-DSWIPL_PACKAGES_GUI=ON` (10+) / `-DSWIPL_PACKAGES_X=ON` (older), or no `--without-xpce` on the autoconf path |

```sh
SWIPROLOG_ENABLE_JAVA=1 asdf install swiprolog 9.2.9
SWIPROLOG_ENABLE_JAVA=1 SWIPROLOG_ENABLE_GUI=1 asdf install swiprolog 9.2.9
```

The vars are read at install time, so they only affect the version you're installing. Enabling a package for one version and not another is fine.
