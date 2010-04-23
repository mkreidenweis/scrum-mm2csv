#!/usr/bin/perl
#
# This class can transform a Freemind mindmap containing Sprint Planning data to a CSV file for printing Task Cards.
# The Mindmap has to contain nodes matching /Sprint\s+\d{4}-\d{2,}/ that has the Stories as direct children. 
# Tasks that should end up in the CSV file have to be annotated in Freemind by the internal icon "attach" (paper clip).
#
# Copyright: TNG Technology Consulting GmbH 2010
# Author: Martin Kreidenweis <martin.kreidenweis@tngtech.com>
#

package MM2CSV;

use strict;
use warnings;
use Carp;

require Exporter;
our @ISA = qw(Exporter);

use XML::Parser;

my $TASK_IMAGE = 'attach';
my $SPRINT_PATTERN = qr{Sprint\s+\d{4}-\d{2,}};

my $SUBTASK_COUNT = 5;
my @COLUMNS = qw(Sprint Story Category Task Subtask1 Subtask2 Subtask3 Subtask4 Subtask5);

sub new {
    my ($class) = @_;
    my $self = {};

    # header columns
    $self->{'OUTPUT'} .= '"'.join('","', @COLUMNS).'"'."\n";

    bless $self, $class;
}

# sets the given column to the given value
sub set_column {
    my ($self, $column, $text) = @_;

    # remove trailing stuff beginning with numbers (estimations) in parantheses
    my $regex = qr/\s*                   # also remove trailing whitespace before estimation
                   (
                       \(\s*\d[^\)]*\)   # remove stuff in ()
		     |
		       {\s*\d[^}]*}      # same for stuff in {}
		   )
		   \s*$/xms;             # trailing whitespace is removed too
    $text =~ s/$regex//;
    
    $self->{$column} = $text;
}

# sets the given column to the given value and all later colums to the empty string
sub reset_column {
    my ($self, $column, $text) = @_;
    
    $self->set_column($column, $text);
    
    my $rf = 0;
    for my $cur_col (@COLUMNS) {
        $self->{$cur_col} = '' if ($rf);
        $rf = 1 if ($cur_col eq $column);
    }
}

# add current task data to the csv output
sub add_output_line {
    my ($self) = @_;
    
    $self->{'OUTPUT'} .= '"'.join('","', map { quote($self->{$_}) } @COLUMNS).'"'."\n";
}

# goes through the xml tree filling the $self->{<columname>} 
# and adding to output once a task is reached
sub parse {
    my ($self, $input) = @_;
    
    my $parser = new XML::Parser(Style => 'Tree');
    my $parsed = $parser->parse($input);
    
    croak 'Invalid input format' unless ($parsed->[0] eq 'map');

    # iterate over Sprints
    my @sprints = select_matching_nodes($SPRINT_PATTERN, $parsed->[1], 2);
    for my $tree (@sprints) {
        my $sprint = $tree->[0]->{'TEXT'};
        $sprint =~ s/^.*(\d{4}-\d{2}).*$/$1/;
        $self->reset_column('Sprint', $sprint);
        
        # loop through stories
        my $i = 1;
        while ($i < scalar @{$tree}) {
            if ($tree->[$i] eq 'node') {
                $self->reset_column('Story', $tree->[$i+1][0]{'TEXT'});
                
                $self->traverse_story($tree->[$i+1]);
            }
            $i += 2;
        }
    }
}

# recursively traverse a story down to the tasks
sub traverse_story {
    my ($self, $tree, $category) = @_;
    
    $category = '' unless (defined $category);

    my $i = 1;
    while ($i < scalar @{$tree}) {
        if ($tree->[$i] eq 'node') {
            if (is_task($tree->[$i+1])) {
                $self->reset_column('Task', $tree->[$i+1][0]{'TEXT'});
                $self->handle_task($tree->[$i+1]);
            }
            else {
                $self->set_column('Category', $category . ($category ? ' ' : '') . $tree->[$i+1][0]{'TEXT'});
                $self->traverse_story($tree->[$i+1], $self->{'Category'});
            }
        }
        $i += 2;
    }       
}

# handle task node with subtask nodes
sub handle_task {
    my ($self, $tree) = @_;

    my @subtasks;

    # flatten subtasks
    my $i = 1;
    while ($i < scalar @{$tree}) {
        if ($tree->[$i] eq 'node') {
            push @subtasks, parse_hierarchy($tree->[$i+1]);
        }
        $i += 2;
    }
    
    # write them to columns
    $i = 0;
    for my $subtask (@subtasks) {
        $i++;
        if ($i < $SUBTASK_COUNT) {
            $self->{"Subtask$i"} = $subtask;
        }
        else {
            last;
        }
    }
    # last subtask will contain all tasks that don't fit into $SUBTASK_COUNT subtask columns
    if ($i == $SUBTASK_COUNT) {
        $self->{"Subtask$i"} = join('; ', @subtasks[$i-1..$#subtasks]);
    }
    
    $self->add_output_line();
}

# returns 1 if the given array reference represents the contents of a task node
# (tasks are marked with the builtin freemind image $TASK_IMAGE)
sub is_task {
    my ($tree) = @_;
    
    my $i = 1;
    while ($i < scalar @{$tree}) {
        if ($tree->[$i] eq 'icon' && $tree->[$i+1][0]{'BUILTIN'} eq $TASK_IMAGE) {
            return 1;
        }
        $i += 2;
    }
}

# replaces " with "" for CSV quoting
sub quote {
    my ($in) = @_;
    
    $in =~ s/"/""/g;
    
    return $in;
}

# takes a hierachy of nodes and makes a flat string representation with parantheses out of it
sub parse_hierarchy {
    my ($tree) = @_;

    my @subnodes;
    my $i = 1;
    while ($i < scalar @{$tree}) {
        if ($tree->[$i] eq 'node') {
            push @subnodes, parse_hierarchy($tree->[$i+1]);
        }
        $i += 2;
    }
    
    return $tree->[0]{'TEXT'} . (@subnodes ? ' (' . join(', ', @subnodes) . ')' : '');
}

# recursively find nodes with the given text down to $max_depth
sub select_matching_nodes {
    my ($expression, $tree, $max_depth) = @_;

    return () if ($max_depth == 0);

    my @result = ();

    my $i = 1;
    while ($i < scalar @{$tree}) {
        if ($tree->[$i] eq 'node') {
            if ($tree->[$i+1][0]{'TEXT'} =~ $expression) {
                push @result, $tree->[$i+1];
            } 
            else {
                push @result, select_matching_nodes($expression, $tree->[$i+1], $max_depth-1);
            }
        }
        $i += 2;
    }

    return @result;
}

# returns output generated by the parse method
sub get_output {
    my ($self) = @_;
    
    return $self->{'OUTPUT'};
}

1;
