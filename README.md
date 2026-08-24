
# Perlanet

[![Build Status](https://github.com/davorg-cpan/perlanet/actions/workflows/perltest.yml/badge.svg?branch=master)](https://github.com/davorg-cpan/perlanet/actions/workflows/perltest.yml) [![Coverage Status](https://coveralls.io/repos/github/davorg-cpan/perlanet/badge.svg?branch=master)](https://coveralls.io/github/davorg-cpan/perlanet?branch=master)

## What is Perlanet?

Perlanet is a Perl tool for building **planet sites** — aggregated pages that
pull together blog posts and articles from multiple web feeds into one place.

If you run a community, team, or project and want to showcase what your members
are writing about, Perlanet makes it easy. Point it at a list of Atom or RSS
feeds, and it will generate a combined web page and/or feed with the latest
content from all of them. It's the glue that turns a collection of individual
voices into a shared hub.

## Installation

The easiest way to install Perlanet is with
[`cpanm`](https://metacpan.org/pod/App::cpanminus):

```sh
cpanm Perlanet
```

Alternatively, you can use the traditional `cpan` client:

```sh
cpan Perlanet
```

The latest released version is always available on
[CPAN](https://metacpan.org/dist/Perlanet).

## Documentation

Full documentation is included with the distribution in POD format. After
installing, you can read it with:

```sh
perldoc perlanet
```

## Getting Help / Reporting Bugs

Found a bug or have a feature request? Please open an issue on the
[GitHub issue tracker](https://github.com/davorg-cpan/perlanet/issues).

## Author

Dave Cross

## Copyright

Copyright (C) 2008, Magnum Solutions Ltd. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

