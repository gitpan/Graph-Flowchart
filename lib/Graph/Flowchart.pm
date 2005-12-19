#############################################################################
# Generate flowcharts as a Graph::Easy object
#
# (c) by Tels 2004-2005.
#############################################################################

package Graph::Flowchart;

$VERSION = '0.05';

use strict;
use warnings;

use Graph::Easy;
use Graph::Flowchart::Node qw/
  N_IF N_THEN N_ELSE
  N_END N_START N_BLOCK N_JOINT
  N_FOR N_CONTINUE
  /;

#############################################################################
#############################################################################

sub new
  {
  my $class = shift;

  my $self = bless {}, $class;

  my $args = $_[0];
  $args = { @_ } if ref($args) ne 'HASH';

  $self->_init($args);
  }

sub _init
  {
  my ($self, $args) = @_;

  $self->{graph} = Graph::Easy->new();

  # make the chart flow down
  my $g = $self->{graph};

  $g->set_attribute('flow', 'down');

  # set class defaults
  $g->set_attribute('node.point', 'shape', 'point');
  $g->set_attribute('node.start', 'border-style', 'bold');
  $g->set_attribute('node.end', 'border-style', 'bold');
  for my $s (qw/block if for/)
    {
    $g->set_attribute("node.$s", 'border-style', 'solid');
    }

  # add the start node
  $self->{_last} = $self->new_block ('start', N_START() );

  $g->add_node($self->{_last});
#  $g->debug(1);

  $self->{_first} = $self->{_last};
  $self->{_cur} = $self->{_last};

  $self;
  }

sub as_graph
  {
  # return the internal Graph::Easy object
  my $self = shift;

  $self->{graph};
  }

sub as_ascii
  {
  my $self = shift;

  $self->{graph}->as_ascii();
  }

sub as_html_file
  {
  my $self = shift;

  $self->{graph}->as_html_file();
  }

sub as_boxart
  {
  my $self = shift;

  $self->{graph}->as_boxart();
  }

#############################################################################

sub last_block
  {
  # get/set the last block
  my $self = shift;

  $self->{_last} = $_[0] if ref($_[0]) && $_[0]->isa('Graph::Flowchart::Node');

  $self->{_last};
  }

sub current_block
  {
  # get/set the current insertion point
  my $self = shift;

  $self->{_cur} = $_[0] if ref($_[0]) && $_[0]->isa('Graph::Flowchart::Node');

  $self->{_cur};
  }

sub first_block
  {
  # get/set the first block
  my $self = shift;

  $self->{_first} = $_[0] if ref($_[0]) && $_[0]->isa('Graph::Flowchart::Node');

  $self->{_first};
  }

#############################################################################

sub new_block
  {
  my ($self, $label, $type) = @_;

  Graph::Flowchart::Node->new( $label, $type );    
  }

#############################################################################

sub merge_blocks
  {
  # if possible, merge the given two blocks
  my ($self, $first, $second) = @_;

  # see if we should merge the blocks

  return $second
	if ( ($first->{_type} != N_JOINT()) &&
	     ($first->{_type} != $second->{_type} ) );
   
  my $g = $self->{graph};

  my $label = $first->label();
  $label .= '\n' unless $label eq '';
  $label .= $second->label();

#  print STDERR "# merge $first->{name} $second->{name}\n";

  $first->sub_class($second->sub_class()) if $first->{_type} == N_JOINT;

  $first->set_attribute('label', $label);
  $first->{_type} = $second->{_type};

  # drop second node from graph
  $g->merge_nodes($first, $second);

  $self->{_cur} = $first;
  }

#############################################################################

sub connect
  {
  my ($self, $from, $to, $edge_label) = @_;

  my $g = $self->{graph};
  my $edge = $g->add_edge($from, $to);

  $edge->set_attribute('label', $edge_label) if defined $edge_label;

  $edge;
  }

sub add_block
  {
  my ($self, $block, $where) = @_;

  $block = $self->new_block($block, N_BLOCK() ) unless ref $block;

  $where = $self->{_cur} unless defined $where;
  my $g = $self->{graph};

  $g->add_edge($where, $block);

  $block = $self->merge_blocks($where, $block);

  $self->{_cur} = $block;			# set new _cur and return it
  }

sub add_joint
  {
  my $self = shift;

  my $g = $self->{graph};

  my $joint = $self->new_block('', N_JOINT());
  $g->add_node($joint);

  # connect the requested connection points to the joint
  for my $node ( @_ )
    {
    $g->add_edge($node, $joint);
    }

  $joint;
  }

sub add_if_then
  {
  my ($self, $if, $then, $where) = @_;
 
  $if = $self->new_block($if, N_IF()) unless ref $if;
  $then = $self->new_block($then, N_THEN()) unless ref $then;

  $where = $self->{_cur} unless defined $where;
  my $g = $self->{graph};

  $if = $self->add_block ($if, $where);

  $self->connect($if, $then, 'true');

  # then --> '*'
  $self->{_cur} = $self->add_joint($then);

  # if -- false --> '*'
  $self->connect($if, $self->{_cur}, 'false');

  $self->{_cur};
  }

sub add_if_then_else
  {
  my ($self, $if, $then, $else, $where) = @_;

  return $self->add_if_then($if,$then,$where) unless defined $else;
 
  $if = $self->new_block($if, N_IF()) unless ref $if;
  $then = $self->new_block($then, N_THEN()) unless ref $then;
  $else = $self->new_block($else, N_ELSE()) unless ref $else;

  $where = $self->{_cur} unless defined $where;
  my $g = $self->{graph};

  $if = $self->add_block ($if, $where);
  
  $self->connect($if, $then, 'true');
  $self->connect($if, $else, 'false');

  # then --> '*', else --> '*'
  $self->{_cur} = $self->add_joint($then, $else);

  $self->{_cur};
  }

#############################################################################
# for loop

sub add_for
  {
  # add a for (my $i = 0; $i < 12; $i++) style loop
  my ($self, $init, $while, $cont, $body, $where) = @_;
 
  $init = $self->new_block($init, N_FOR()) unless ref $init;
  $while = $self->new_block($while, N_IF()) unless ref $while;
  $cont = $self->new_block($cont, N_CONTINUE()) unless ref $cont;
  $body = $self->new_block($body, N_BLOCK()) unless ref $body;

  # init -> if $while --> body --> cont --> (back to if)

  $where = $self->{_cur} unless defined $where;
  my $g = $self->{graph};

  $init = $self->add_block ($init, $where);
  $while = $self->add_block ($while, $init);
  
  # Make the for-head node a bigger because it has two edges leaving it, and
  # one coming back and we want two of them on one side for easier layouts:
  $while->set_attribute('rows',2);

  $self->connect($while, $body, 'true');

  $self->connect($body, $cont);
  $self->connect($cont, $while);

  my $joint = $self->add_joint();
  $self->connect($while, $joint, 'false');

  $self->{_cur} = $joint;

  ($joint, $body);
  }

#############################################################################
# while loop

sub add_while
  {
  # add a "while ($i < 12) { body } continue { cont }" style loop
  my ($self, $while, $body, $cont, $where) = @_;
 
  $while = $self->new_block($while, N_IF()) unless ref $while;

  # no body?
  $body = $self->new_block( '', N_JOINT()) if !defined $body;
  $body = $self->new_block($body, N_BLOCK()) unless ref $body;

  $cont = $self->new_block($cont, N_CONTINUE()) if defined $cont && !ref $cont;

  # if $while --> body --> cont --> (back to if)

  $where = $self->{_cur} unless defined $where;
  my $g = $self->{graph};

  $while = $self->add_block ($while, $where);
  
  # Make the head node a bigger because it has two edges leaving it, and
  # one coming back and we want two of them on one side for easier layouts:
  $while->set_attribute('rows',2);

  $self->connect($while, $body, 'true');

  if (defined $cont)
    {
    $cont = $self->add_block ($cont, $body);
    $self->connect($cont, $while);
    }
  else 
    { 
    $self->connect($body, $while);
    }

  my $joint = $self->add_joint();
  $self->connect($while, $joint, 'false');

  $self->{_cur} = $joint;

  ($joint, $body, $cont);
  }

#############################################################################

sub finish
  {
  my ($self, $where) = @_;

  my $g = $self->{graph};

  my $end = $self->new_block ( 'end', N_END() );

  $end = $self->add_block ($end, $where);
 
  $self->{_last} = $end;
  }

1;
__END__

=head1 NAME

Graph::Flowchart - Generate easily flowcharts as Graph::Easy objects

=head1 SYNOPSIS

	use Graph::Flowchart;

	my $flow = Graph::Flowchart->new();

	print $flow->as_ascii();

=head1 DESCRIPTION

This module lets you easily create flowcharts as Graph::Easy
objects. This means you can output your flowchart as HTML,
ASCII, Boxart (unicode drawing) or SVG.

X<graph>
X<ascii>
X<html>
X<svg>
X<boxart>
X<unicode>
X<flowchart>
X<diagram>

=head2 Classes

The nodes constructed by the various C<add_*> methods will set the subclass
of the node according to the following list:

=over 2

=item start

The start block.

=item end

The end block, created by C<finish()>.

=item block

Orindary code blocks, f.i. from C<$b = 9;>.

=item if, for, while

Blocks for the various constructs for conditional and loop constructs.

=back

Each class will get some default attributes, like C<if> constructs having
a diamond-shape.

You can override the graph appearance most easily by changing the
(sub)-class attributes:

	my $chart = Graph::Flowchart->new();

	$chart->add_block('$a = 9;');
	$chart->add_if_then('$a == 9;', '$b = 1;');
	$chart->finish();

	my $graph = $chart->as_graph();

Now C<$graph> is a C<Graph::Easy> object and you can manipulate the
class attributes like so:

	$graph->set_attribute('node.if', 'fill', 'red');
	print $graph->as_html_file();

This will color all conditional blocks red.
 
=head1 EXPORT

Exports nothing.

=head1 METHODS

All block-inserting routines on the this model will insert the
block on the given position, or if this is not provided,
on the current position. After inserting the blocks, the current
position will be updated.

In addition, the newly inserted block(s) might be merged with
blocks at the current position.

=head2 new()

	my $grapher = Graph::Flowchart->new();

Creates a new C<Graph::Flowchart> object.

=head2 as_graph()

	my $graph = $grapher->as_graph();

Return the internal data structure as C<Graph::Easy> object.

=head2 as_ascii()

	print $grapher->as_ascii();

Returns the flow chart as ASCII art drawing.

=head2 as_boxart()

	print $grapher->as_boxart();

Returns the flow chart as a Unicode boxart drawing.

=head2 as_html_file()

	print $grapher->as_html_file();

Returns the flow chart as entire HTML page.

=head2 current_block()

	my $insertion = $grapher->current_block();	# get
	$grapher->current_block( $block);		# set

Get or set the current block in the flow chart, e.g. where new code blocks
will be inserted by the C<add_*> methods.

Needs a C<Graph::Flowchart::Node> as argument, which is usually
an object returned by one of the C<add_*> methods.

=head2 first_block()

	my $first = $grapher->first_block();		# get
	$grapher->first_block( $block );		# set

Get or set the first block in the flow chart, usually the 'start' block.

Needs a C<Graph::Flowchart::Node> as argument, which is usually
an object returned by one of the C<add_*> methods.

=head2 last_block()

	my $last = $grapher->last_block();		# get
	$grapher->last_block( $block);			# set

Get or set the last block in the flow chart, usually the block where you
last added something via one of the C<add_*> routines.

Needs a C<Graph::Flowchart::Node> as argument, which is usually
an object returned by one of the C<add_*> methods.

The returned block will only be the last block if you call C<finish()>
beforehand.

=head2 finish()

	my $last = $grapher->finish( $block );
	my $last = $grapher->finish( );

Adds an end-block. If no parameter is given, uses the current position,
otherwise appends the end block to the given C<$block>. See also
C<current_block>. Will also update the position of C<last_block> to point
to the newly added block, and return this block.

=head2 new_block()

	my $block = $grapher->new_block( $label, $type );

Creates a new block from the given label and type. The type is one
of the C<N_*> from C<Graph::Flowchart::Node>.

=head2 add_block()

	my $current = $grapher->add_block( $block );
	my $current = $grapher->add_block( $block, $where );

Add the given block. See C<new_block> on creating the block before hand.

The optional C<$where> parameter is the point where the code will be
inserted. If not specified, it will be appended to the current block,
see C<current_block>.

Returns the newly added block as current.

Example:

        +---------+
    --> | $a = 9; | -->
        +---------+

=head2 add_if_then()

	my $current = $grapher->add_if_then( $if, $then);
	my $current = grapher->add_if_then( $if, $then, $where);

Add an if-then branch to the flowchart. The optional C<$where> parameter
defines at which block to attach the construct.

Returns the new current block, which is a C<joint>.

Example:

                                             false
          +--------------------------------------------+
          |                                            v
        +-------------+  true   +---------+
    --> | if ($a = 9) | ------> | $b = 1; | ------->   *   -->
        +-------------+         +---------+

=head2 add_if_then_else()

	my $current = $grapher->add_if_then_else( $if, $then, $else);
	my $current = $grapher->add_if_then_else( $if, $then, $else, $where);

Add an if-then-else branch to the flowchart.

The optional C<$where> parameter defines at which block to attach the
construct.

Returns the new current block, which is a C<joint>.

Example:

        +-------------+
        |   $b = 2;   | --------------------------+
        +-------------+                           |
          ^                                       |
          | false                                 |
          |                                       v
        +-------------+  true   +---------+
    --> | if ($a = 9) | ------> | $b = 1; | -->   *   -->
        +-------------+         +---------+

If C<$else> is not defined, works just like C<add_if_then()>.

=head2 add_for()

	my ($current,$body) = $grapher->add_for( $init, $while, $cont, $body);
	my ($current,$body) = $grapher->add_for( $init, $while, $cont, $body, $where);

Add a C<< for (my $i = 0; $i < 12; $i++) { ... } >> style loop.

The optional C<$where> parameter defines at which block to attach the
construct.

This routine returns two block positions, the current block (e.g. after
the loop) and the block of the loop body.

Example:

        +--------------------+  false        
    --> |   for: $i < 10;    | ------->  *  -->
        +--------------------+
          |                ^
          | true           +----+
          v                     |
        +---------------+     +--------+
        |     $a++;     | --> |  $i++  |
        +---------------+     +--------+

=head2 add_while

  	my ($current,$body, $cont) = 
	  $grapher->add_while($while, $body, $cont, $where) = @_;

To skip the continue block, pass C<$cont> as undef.

This routine returns three block positions, the current block (e.g. after
the loop), the block of the loop body and the continue block.


Example of a while loop with only the body (or only the C<continue> block):


        +----------------------+  false  
    --> |   while ($b < 19)    | ------->  *  -->
        +----------------------+
          |                  ^
          | true             |
          v                  |
        +-----------------+  |
        |      $b++;      |--+
        +-----------------+

Example of a while loop with body and continue block (not similiarity to for
loop):

        +--------------------+  false        
    --> | while ($i < 10)    | ------->  *  -->
        +--------------------+
          |                ^
          | true           +----+
          v                     |
        +---------------+     +--------+
        |     $a++;     | --> |  $i++  |
        +---------------+     +--------+

=head2 add_joint()

	my $joint = $grapher->add_joint( @blocks );

Adds a joint (an unlabeled, star-shaped node) to the flowchart and then
connects each block in the given list to that joint. This is used
f.i. by if-then-else constructs that need a common joint where all
the branches join together again.

When adding a block right after a joint, they will be merged together
and the joint will be effectively replaced by the block.

Example:

    -->   *   -->

=head2 merge_blocks()

	$grapher->merge_blocks($first,$second);

If possible, merge the given two blocks into one block, keeping all connections
to the first, and all from the second. Any connections between the two
blocks is dropped.

Example:

        +---------+     +---------+
    --> | $a = 9; | --> | $b = 2; | -->
        +---------+     +---------+

This will be turned into:

        +---------+ 
    --> | $a = 9; | -->
        | $b = 2; | 
        +---------+

=head2 connect()

	my $edge = $grapher->connect( $from, $to );
	my $edge = $grapher->connect( $from, $to, $edge_label );

Connects two blocks with an edge, setting the optional edge label.

Returns the C<Graph::Easy::Edge> object for the connection.
 
=head1 SEE ALSO

L<Graph::Easy>.

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms of the GPL version 2.
See the LICENSE file for information.

X<gpl>

=head1 AUTHOR

Copyright (C) 2004-2005 by Tels L<http://bloodgate.com>

X<tels>
X<bloodgate.com>

=cut
