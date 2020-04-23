## [Unreleased] - TBD
- no changes

## [1.1.0] - 2020-04-23
- added Dockerfile


## [1.0.0] - 2019-10-27
- initial release
- MIT License
- includes README.md and CHANGELOG.md
- includes Makefile for test and install
  - `make all`
  - `make test`
  - `make install`
- initial functionality includes
  - parsing of `yaml`-like .gitfile
    - source
    - path
    - version
    - supports comments with `#`
  - cli paramters for
    - help (-h/--help)
    - configuring .gitfile location (-f/--gitfile)
    - configuring default clone path (-p/--default-clone-path)
