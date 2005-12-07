#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 2;
   chdir 't' if -d 't';
   use lib '../lib';
   };

SKIP:
  {
  skip("Test::Pod::Coverage 1.00 required for testing POD coverage", 1)
    unless do {
    eval "use Test::Pod::Coverage 1.00";
    $@ ? 0 : 1;
    };
  for my $m (qw/
    Graph::Flowchart
   /)
    {
    pod_coverage_ok( $m, "$m is covered" );
    }

  # Define the global CONSTANTS for internal usage
  my $trustme = { trustme => [ qr/^(
	N_BLOCK|
	N_BODY|
	N_CONTINUE|
	N_ELSE|
	N_END|
	N_FOR|
	N_IF|
	N_JOINT|
	N_START|
	N_THEN
    )\z/x ] };
  pod_coverage_ok( "Graph::Flowchart::Node", $trustme );
  }
