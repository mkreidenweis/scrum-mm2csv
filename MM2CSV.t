#!/usr/bin/perl 

use warnings;
use strict;

use Data::Dumper;

use Test::More tests => 2;

require_ok('MM2CSV');

# load reference file
open INPUT, '<', 'MM2CSV.t.input.mm';
my @input = <INPUT>;
my $input = "@input";
close INPUT;

my $expected = <<END;
"Sprint","Story","Category","Task","Subtask1","Subtask2","Subtask3","Subtask4","Subtask5"
"2010-20","asdf","","foo","","","","",""
"2010-20","asdf","","bar ""foobar""","","","","",""
"2010-21","Some Story: A tale about...","Dev","buy Mindstorms set","","","","",""
"2010-21","Some Story: A tale about...","Dev","write remote control perl script","write unit tests","write module (mod1, mod2 (part a, part b))","","",""
"2010-21","Some Story: A tale about...","Dev","install replacement firmware","","","","",""
"2010-21","Some Story: A tale about...","CT","regression","","","","",""
"2010-21","Some Story: A tale about...","Deployment","deploy to production","","","","",""
"2010-21","Another Story","","Do one thing","","","","",""
"2010-21","Another Story","","do another thing","","","","",""
"2010-21","Another Story","cat subcat1","task1","subtask1","subtask2","subtask3","subtask4","subtask5; subtask6; subtask7"
"2010-21","Another Story","cat subcat1","task2","","","","",""
"2010-21","Another Story","cat subcat2","taskX","","","","",""
END


my $m = MM2CSV->new();
$m->parse($input);

is($m->get_output(), $expected, 'parsing works as expected');
