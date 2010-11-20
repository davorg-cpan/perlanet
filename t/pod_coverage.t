use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
all_pod_coverage_ok({ also_private => [ qr/^(BUILD|LC_ALL|TIDY_WARNING)/ ] } );

