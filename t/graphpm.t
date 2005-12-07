#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 7;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Flowchart") or die($@);
   };

#############################################################################

can_ok ('Graph::Flowchart',
  qw/
    new
    first_block
    last_block
    current_block

    as_graph
    as_html_file
    as_ascii
    as_boxart

    new_block

    add_block
    add_joint
    add_if_then
    add_if_then_else
    add_for
    add_while
  /);

#############################################################################
# OO interface

my $grapher = Graph::Flowchart->new();

my $first = $grapher->first_block();
my $last = $grapher->first_block();
my $curr = $grapher->current_block();

my $c = 'Graph::Flowchart::Node';

is (ref($first), $c);
is (ref($last), $c);
is (ref($curr), $c);

is ($curr, $last, 'last and curr are the same');
is ($curr, $first, 'first and curr are the same');



