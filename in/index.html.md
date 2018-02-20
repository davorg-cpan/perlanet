# NAME

perlanet - command line interface to Perlanet.pm

# SYNOPSIS

    $ perlanet

Or

    $ perlanet config_file

# DESCRIPTION

`perlanet` is a command line program for aggregating web feeds (both Atom
and RSS) and publishing a new web page and a new web feed containing the
results of that aggregation.

# COMMAND LINE ARGUMENTS

`perlanet` takes one optional command line argument, which is the name of
a configuration file to use. If no filename is given then the program looks
for a file called `perlanetrc` in the current directory.

# CONFIGURATION FILE

`perlanet` requires a configuration file which contains details of which
feeds to aggregate and what to do with the results of the aggregation. By
default, `perlanet` looks for a file called `perlanetrc` in the current
directory, but this name can be overridden by passing the name of a different
file when calling the program.

The configuration file is in YAML format. YAML is a simple text-based file
format. See [http://yaml.org/](http://yaml.org/) for further details.

## Configuration Options

The configuration file can contain the following options.

- title

    The title of the resulting page and web feed. This option is mandatory.

- description

    The description of the resulting page and web feed. This option is mandatory.

- url

    A URL which will be associated with the resulting page and web feed. This will
    usually be the address where the web page will be published. This option is
    mandatory.

- author

    The name and email address of the author of the aggregated content. This
    item has two sub-items - one each for the name and email address. This option
    is mandatory.

- agent

    This optional entry defines the agent string that perlanet will use when
    requesting data from web sites. It's the name of the program that site owners
    will see in their web site access logs. Although it is optional, it is strongly
    recommended that you give a value for this configuration option and that the
    value you use includes contact details so that web site owners can get in
    touch with you if they have any concerns about your use of their site.

- entries

    The maximum number of entries to include in the aggregated content. This option
    is mandatory.

- entries\_per\_feed

    The `entries` value above defines the total number of entries in the
    aggregated output feed. The &lt;entries\_per\_feed> value defines the number of
    entries to take from each of your source feeds. For example, if this is
    set to 1 then there will only be one entry from each feed in your output.
    If this value is 0 (or missing) then all values from all source feeds are
    used.

- entry\_sort\_order

    Entries have two dates, issued (which is the date that the item was first
    published) and modified (which is the date that the item was last updated).
    This configuration option controls which of these two dates are used to sort
    the entries in a feed. It can be one of the two values `issued` or
    `modified`. If this option is omitted, then `modified` is used.

- opml

    The system can optionally create an OPML file containing details of the
    feeds which are being aggregated. This optional option controls whether or not
    this file is created. If it exists, it should be the name of the OPML file
    to be created. If an OPML file is being created, then the `feeds` options
    (described below) will all require a `web` sub-option.

- page

    This mandatory option contains the details of the web page to be created.
    There are two sub-options - `file` gives the name of the file to be created
    and `template` gives the name of a Template Toolkit template which will be
    processed in order to create this file. See the section ["Output Template"](#output-template)
    for more details on this template, and the web site [http://tt2.org/](http://tt2.org/) for
    more information about the Template Toolkit.

- feed

    This mandatory option contains the details of the web feed to be created.
    There are two sub-options - `file` gives the name of the file to be created
    and `format` gives the format of the output (currently 'Atom' or 'RSS').

- cache\_dir

    This if you give a directory name in this option then perlanet will use the
    cache facility of URI::Fetch. This means that web feeds will only be downloaded
    when they change.

- feeds

    This mandatory option gives details of the web feeds to be aggregated. Each
    item on the list has one mandatory sub-option and two optional sub-options.
    The mandatory sub-option is `url` which gives the URL of the feed. The
    optional sub-option `title` gives a title which will be prepended to all of
    the entry titles taken from that feed. If no title is given, then the title
    will be taken from the feed title. The optional `web` sub-option gives a
    web site URL associated with the feed (often the address of the web site that
    the feed comes from). This can be used to create a list of the aggregated
    sites. The `web` sub-option becomes mandatory if you are creating an OPML
    file.

## Example Configuration File

    title: planet test
    description: A Test Planet
    url: http://planet.example.com/
    author:
      name: Dave Cross
      email: dave@dave.org.uk
    entries: 20
    opml: opml.xml
    page:
      file: index.html
      template: index.tt
    feed:
      file: atom.xml
      format: Atom
    cache_dir: /tmp/feeds
    feeds:
      - url: http://blog.dave.org.uk/atom.xml
        title: Dave's Blog
        web: http://blog.dave.org.uk/
      - url: http://use.perl.org/~davorg/journal/rss
        title: Dave's use.perl Journal
        web: http://use.perl.org/~davorg/journal/
      - url: http://www.oreillynet.com/pub/feed/31?au=2607
        title: Dave on O'Reillynet
        web: http://www.oreillynet.com/pub/au/2607

## Output Template

The web page is created from a Template Toolkit template. This template is
passed two variables.

- feed

    This is the XML::Feed object which has been used to create the aggregated
    feed. See the [XML::Feed](https://metacpan.org/pod/XML::Feed) documentation for details of the data that is
    held in this object.

- cfg

    This is the contents of the configuration file, converted to a (nested)
    Perl hash.

## Example Output Template

This is a simple template which uses the `feed` variable to display details
of the aggregated feeds.

    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
    <html>
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <title>[% feed.title %]</title>
      </head>
      <body>
        <h1>[% feed.title | html %]</h1>
        <p>[% feed.description | html %]</p>
    [% FOREACH entry IN feed.entries %]
        <h2><a href="[% entry.link | url | html %]">[% entry.title | html %]</h2></a>
        [% entry.content.body %]
    [% IF entry.author OR entry.issued %]
        <p>Published[% IF entry.author %] by [% entry.author | html; END %]
        [% IF entry.issued %] on [% entry.issued | html; END %]</p>
    [% END %]
    [% END %]
        <hr />
        <address>[% feed.author | html %] / [% feed.modified | html %]</address>
      </body>
    </html>

In the future, the Perlanet wiki at [http://wiki.github.com/davorg/perlanet](http://wiki.github.com/davorg/perlanet)
will contain a cookbook of useful ideas to include in the output template.

# SUPPORT

There is a mailing list which acts as both a place for developers to talk
about maintaining and improving Perlanet and also for users to get support.
You can sign up to this list at
[http://lists.mag-sol.com/mailman/listinfo/perlanet](http://lists.mag-sol.com/mailman/listinfo/perlanet)

To report bugs in Perlanet, please use the CPAN request tracker. You can
either use the web page at
[http://rt.cpan.org/Public/Bug/Report.html?Queue=Perlanet](http://rt.cpan.org/Public/Bug/Report.html?Queue=Perlanet) or send an email
to bug-Perlanet@rt.cpan.org.

# SEE ALSO

- [perlanet](https://metacpan.org/pod/perlanet)
- [Plagger](https://metacpan.org/pod/Plagger)

# AUTHOR

Dave Cross, <dave@mag-sol.com>

# COPYRIGHT AND LICENSE

Copyright (C) 2008 by Magnum Solutions Ltd.

This progam library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.
