#!/usr/bin/perl
#
# this is a wrapper script around MM2CSV.pm
# it takes a Freemind Mindmap in XML format from STDIN and prints the CSV file to STDOUT
#

use warnings;
use strict;

require MM2CSV;

my @input = <>;

if (@input) {
    my $m = MM2CSV->new();
    $m->parse("@input");
    
    print STDOUT $m->get_output();
    
    exit 0;
}
else {
    print STDERR "No input given.";
    
    exit 1;
}
