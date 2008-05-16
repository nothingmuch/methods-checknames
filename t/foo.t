#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use Methods::CheckNames;

sub Foo::foo {  }

my Foo $x = bless {}, "Foo";
my $ran = 0;

eval '$ran++; $x->foo()';
ok(!$@, "no error for acutal method");
is($ran, 1, "ran");

$ran = 0;
eval '$ran++; $x->bar()';
ok($@, "error for non existent method");
is($ran, 0, "compile time error");
