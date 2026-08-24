
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

## Examples

### A simple planet site

Create a directory for your planet and add a configuration file called
`perlanetrc`:

```yaml
title: My Community Planet
description: The latest posts from our community
url: https://planet.example.com/
author:
  name: Alice Example
  email: alice@example.com
entries: 20
page:
  file: index.html
  template: index.tt
feed:
  file: atom.xml
  format: Atom
feeds:
  - feed: https://alice.example.com/feed.xml
    title: Alice's Blog
    web: https://alice.example.com/
  - feed: https://bob.example.com/atom.xml
    title: Bob's Blog
    web: https://bob.example.com/
  - feed: https://carol.example.com/rss
    title: Carol's Blog
    web: https://carol.example.com/
```

You'll also need a [Template Toolkit](https://template-toolkit.org/) template
(`index.tt`) that describes how the HTML page should look. A minimal example:

```html
<!DOCTYPE html>
<html>
  <head><title>[% feed.title %]</title></head>
  <body>
    <h1>[% feed.title | html %]</h1>
    <p>[% feed.description | html %]</p>
    [% FOREACH entry IN feed.entries %]
    <h2><a href="[% entry.link | url | html %]">[% entry.title | html %]</a></h2>
    [% entry.content.body %]
    [% END %]
  </body>
</html>
```

Then run Perlanet from that directory:

```sh
perlanet
```

Perlanet will fetch all the feeds, merge the latest entries, and write two
files into the current directory:

- **`index.html`** — a ready-to-serve HTML page built from your template
- **`atom.xml`** — an Atom feed of the aggregated content

Upload (or symlink) those files to your web server and you're done!

> **Tip:** Pass the name of a different config file as the first argument
> if you don't want to use the default `perlanetrc`:
> ```sh
> perlanet /etc/myplanet/config.yml
> ```

### Keeping the site fresh with cron

A planet site is most useful when it updates itself automatically. Add a cron
job to regenerate the site as often as you like. To refresh every hour, run:

```sh
crontab -e
```

and add a line like this (adjust the paths to match your setup):

```cron
0 * * * * cd /var/www/planet && perlanet >> /var/log/perlanet.log 2>&1
```

This runs Perlanet at the top of every hour, writing any output to a log file
so you can debug problems later. Change `0 * * * *` to whatever schedule suits
you — for example `*/30 * * * *` for every 30 minutes.

### Automated publishing with Docker and GitHub Actions/Pages

If you'd rather not manage a server at all, you can use the official Docker
image (`davorg/perl-perlanet`) together with GitHub Actions to regenerate your
planet on a schedule and publish it automatically to **GitHub Pages**.

1. Create a repository (e.g. `myorg/planet`) containing your `perlanetrc` and
   `index.tt` template.

2. Add a GitHub Actions workflow at `.github/workflows/planet.yml`:

```yaml
name: Build and publish planet

on:
  schedule:
    - cron: '0 * * * *'   # rebuild every hour
  workflow_dispatch:        # allow a manual trigger too

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Build planet
        run: |
          docker run --rm \
            -v "${{ github.workspace }}:/planet" \
            -w /planet \
            davorg/perl-perlanet \
            perlanet

      - name: Publish to GitHub Pages
        uses: peaceiris/actions-gh-pages@v4
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: .
          exclude_assets: '.github,perlanetrc,*.tt'
```

3. Enable GitHub Pages in your repository settings, pointing it at the
   `gh-pages` branch.

That's it. Every hour Actions will pull the latest posts, regenerate
`index.html` and `atom.xml`, and push them to your GitHub Pages site — no
server required.

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

