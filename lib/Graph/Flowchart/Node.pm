#############################################################################
# A node in the graph (includes a type field)
#
# (c) by Tels 2004-2005.
#############################################################################

package Graph::Flowchart::Node;

@ISA = qw/Graph::Easy::Node Exporter/;
$VERSION = '0.05';

use Graph::Easy::Node;
use Exporter;

@EXPORT_OK = qw/
  N_START N_END N_BLOCK N_IF N_THEN N_ELSE N_JOINT N_END N_FOR N_BODY
  N_USE
  N_SUB
  N_CONTINUE N_GOTO N_BREAK N_RETURN N_NEXT N_LAST
  /;

#############################################################################
#############################################################################

use strict;

use constant N_START	=> 1;
use constant N_END	=> 2;
use constant N_BLOCK	=> 3;
use constant N_IF	=> 4;
use constant N_THEN	=> 5;
use constant N_ELSE	=> 6;
use constant N_JOINT	=> 7;
use constant N_FOR	=> 8;
use constant N_BODY	=> 9;
use constant N_CONTINUE	=> 10;
use constant N_GOTO	=> 11;
use constant N_RETURN	=> 12;
use constant N_BREAK	=> 13;
use constant N_NEXT	=> 14;
use constant N_LAST	=> 15;
use constant N_SUB	=> 16;
use constant N_USE	=> 17;

my $subclass = {
  N_START()	=> 'start',
  N_END()	=> 'end',
  N_BLOCK()	=> 'block',
  N_BODY()	=> 'block',
  N_CONTINUE()	=> 'block',
  N_THEN()	=> 'block',
  N_IF()	=> 'if',
  N_ELSE()	=> 'else',
  N_JOINT()	=> 'joint',
  N_FOR()	=> 'for',
  N_GOTO()	=> 'goto',
  N_RETURN()	=> 'return',
  N_NEXT()	=> 'next',
  N_BREAK()	=> 'break',
  N_LAST()	=> 'last',
  N_SUB()	=> 'sub',
  N_USE()	=> 'use',
  };

#############################################################################
#############################################################################

sub new
  {
  my ($class, $label, $type, $labelname, $group) = @_;

  my $self = bless {}, $class;

  $type = N_START() unless defined $type;

  $self->{_type} = $type;
  $self->{_label} = $labelname if defined $labelname;
  $self->{id} = Graph::Easy::Base::_new_id();

  # convert newlines into '\n'
  $label =~ s/([^\\])\\n/$1\\\\n/g;
  $label =~ s/([^\\])\\n/$1\\\\n/g;	# do it twice for consecutive "\n"

  $self->_init( { label => $label, name => $self->{id} } );

  $self->sub_class($subclass->{$type} || 'block');

  if (ref $group)
    {
    $group->add_node($self);
    }

  $self;
  }

sub _set_type
  {
  my $self = shift;

  $self->{_type} = shift;

  $self;
  }

1;
__END__

=head1 NAME

Graph::Flowchart::Node - A node in a Graph::Flowchart, representing a block/expression

=head1 SYNOPSIS

	use Devel::Graph;

	my $graph = Devel::Graph->graph( '$a = 9 if $b == 1' );

	print $graph->as_ascii();

=head1 DESCRIPTION

This module is used by Devel::Graph internally, there should be no need to
use it directly.

=head2 EXPORT

Exports nothing on default but can export on request the following:

  N_START N_END N_BLOCK N_IF N_THEN N_ELSE N_JOINT N_END N_FOR N_BODY
  N_SUB
  N_CONTINUE N_GOTO N_RETURN N_BREAK N_NEXT N_LAST
  N_USE

=head1 METHODS

=head2 new()

	my $node = Graph::Flowchart::Node->new( $text, $type, $label);
	my $node = Graph::Flowchart::Node->new( $text, $type);

Create a new node of the given C<$type> with the C<$text> as label. The
optional C<$label> is the label for C<goto>.

For instance:

	LABEL: $a = 1;
	goto LABEL;

would be turned into:

	my $n1 = Graph::Flowchart::Node->new( "$a = 1;\n", N_BLOCK, 'LABEL'); 
	my $n2 = Graph::Flowchart::Node->new( "goto LABEL;\n", N_GOTO); 

=head1 SEE ALSO

L<Devel::Graph>, <Graph::Easy>.

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms of the GPL version 2.
See the LICENSE file for information.

X<gpl>

=head1 AUTHOR

Copyright (C) 2004-2006 by Tels L<http://bloodgate.com>

X<tels>

=cut
