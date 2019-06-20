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

### Ninja
You'll need the [ninja](https://ninja-build.org/) build tool for versions after `7.7.21-devel`

For versions before `7.7.21-devel` it still uses GNU `autoconf` tools and `make`

### All systems
You'll need these packages (on MacOS) (can install with macports)

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

On linux you need [these ones](http://www.swi-prolog.org/build/prerequisites.html)
