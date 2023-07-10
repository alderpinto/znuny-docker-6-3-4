#!/usr/bin/perl
use strict;
use warnings;
use DateTime qw{};
use Data::Dumper qw{Dumper};
use Plack::Builder qw{builder mount enable};
use MIME::Base64 qw{};
use Plack::Middleware::Expires qw{};
use Plack::Middleware::Session::Cookie qw{};

my $GLOBAL = 0;

my $app = sub {
    my $env     = shift;
    my $session = $env->{'psgix.session'};
    $GLOBAL++;
    $session->{'counter'}++;
    $session->{'init'} ||= DateTime->now->datetime;

    return [
        200,
        [ 'Content-Type' => 'text/plain' ],
        [
          sprintf("Cookie Session Counter: %s\nProcess ID: %s\nGlobal Counter: %s\n\n", $session->{'counter'}, $$, $GLOBAL),
          Dumper($env),
        ],
    ];
};

my $favicon = MIME::Base64::decode('AAABAAEAEBACAAEAAQCwAAAAFgAAACgAAAAQAAAAIAAAAAEAAQAAAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD//wAA//8AAP//AAD//wAA//8AAP//AAD//wAA//8AAP//AAD//wAA//8AAP//AAD//wAA//8AAP//AAD//wAA');

builder {
  mount '/favicon.ico' => builder {
    enable 'Expires', expires => 'access plus 1 years', content_type => 'image/x-icon';
    sub {[200, ['Content-Type' => 'image/x-icon'], [$favicon]]};
  };
  mount '/' => builder {
    enable 'Session::Cookie', secret => 'b8a94f58-6bd9-11eb-9308-0011955df2b8';
    $app;
  }
};