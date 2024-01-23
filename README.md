
# Perlanet

[![Build Status](https://github.com/davorg-cpan/perlanet/actions/workflows/perltest.yml/badge.svg?branch=master)](https://github.com/davorg-cpan/perlanet/actions/workflows/perltest.yml) [![Coverage Status](https://coveralls.io/repos/github/davorg-cpan/perlanet/badge.svg?branch=master)](https://coveralls.io/github/davorg-cpan/perlanet?branch=master)

## NAME

Perlanet

## DESCRIPTION

### WHAT IS Perlanet?

Perlanet is a Perl module for aggregating web feeds.

It allows you to aggregate a number of web feeds (both Atom and RSS) and
to publish a web page and another web feed containing the aggregated
content.

### HOW DO I INSTALL IT?

Perlanet uses the standard Perl module architecture and can therefore by
installed using the standard Perl method which, in brief, goes something
like this:

    gzip -cd Perlanet-X.XX.tar.gz | tar xvf -
    cd Perlanet-X.XX
    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Where X.XX is the version number of the module which you are installing.

You can also install it using either the 'cpan' or 'cpanm' command line
programs.

### WHERE IS THE DOCUMENTATION?

All of the documentation is in POD format. The most useful documentation
is included with the 'perlanet' program that is part of this
distributions. If you install the module using the standard method you
should be able to read it by typing

    perldoc perlanet

at a comand prompt.

### LATEST VERSION

The latest version of this module will always be available from CPAN.

## COPYRIGHT

Copyright (C) 2008, Magnum Solutions Ltd.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

## ANYTHING ELSE?

If you have any further questions, please contact the author.

## AUTHOR

Dave Cross <dave@perlhacks.com>

