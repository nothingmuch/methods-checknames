#!/usr/bin/perl

use strict;

BEGIN {
	unless ( eval "use Test::More 'no_plan'; 1" ) {
		eval '
		my $i = 0;
		sub ok ($;$) {
			$i++;
			print "not " if not $_[0];
			print "ok $_[1]\n";
		}

		sub is ($$;$) {
			ok( $_[0] == $_[1], $_[2] );
		}

		END { print "1..$i\n" }
		';
	}
}

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
