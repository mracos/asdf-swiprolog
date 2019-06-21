# asdf-swiprolog

[![Travis](https://img.shields.io/travis/mracos/asdf-swiprolog/master.svg?style=flat-square)](https://travis-ci.org/mracos/asdf-swiprolog)

[Swiprolog](http://www.swi-prolog.org/) plugin for [asdf](https://github.com/asdf-vm/asdf) version manager

## Install
```
asdf plugin-add swiprolog https://github.com/mracos/asdf-swiprolog.git
```

## Use

Check [asdf](https://github.com/asdf-vm/asdf) readme for instruct on how to install & manage versions of Swi-Prolog

## Before `asdf install`

## Dependencies
- For versions after `7.7.21-devel` you'll need [cmake](https://cmake.org/), since swiprolog started to ship with `CMakeLists.txt` instead of with a `./configure` script

### MacOS (can install with macports)
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
On linux you need [these ones](http://www.swi-prolog.org/build/prerequisites.html)

## :warning:
- By default it installs without the `java_interface` (jpl) and without the `graphics_subsystem` (xpce)
