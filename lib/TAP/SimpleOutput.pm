package TAP::SimpleOutput;

# ABSTRACT: Simple closure-driven TAP generator

use strict;
use warnings;

use Sub::Exporter::Progressive -setup => { exports => [ qw{ counters } ] };

=func counters($level)

This function returns four closures that each generate a different type of TAP
output.  It takes an optional C<$level> that determines the indentation level
(e.g. for subtests).  These coderefs are all closed over the same counter
variable that keeps track of how many test have been run so far; this allows
them to always output the correct test number.

    my ($_ok, $_nok, $_skip, $_plan) = counters();

    $_ok->('whee')   returns "ok 1 - whee"
    $_nok->('boo')   returns "not ok 2 - boo"
    $_skip->('baz')  returns "ok 3 # skip baz"
    $_plan->()       returns "1..3"

Note that calling the C<$_plan> coderef only returns an intelligible response
when called after all the output has been generated; this is analogous to
using L<Test::More> without a declared plan and C<done_testing()> at the end.
If you need or want to specify the plan prior to running tests, you'll need to
do that manually.

=head3 subtests

When C<counter()> is passed an integer, the generated closures all indent
themselves appropriately to indicate to the test harness / TAP parser that a
subtest is being run.  (Namely, each statement returned is prefaced with
C<$level * 4> spaces.)  It's recommended that you use distinct lexical scopes
for subtests to allow the usage of the same variable names (why make things
difficult?) without clobbering any existing ones and to ensure that the
subtest closures are not inadvertently used at an upper level.

    my ($_ok, $_nok) = counters();
    $_ok->('yay!');
    $_nok->('boo :(');
    do {
        my ($_ok, $_nok, $_skip, $_plan) = counters(1);
        $_ok->('thing 1 good');
        $_ok->('thing 2 good');
        $_ok->('thing 3 good');
        $_skip->('over there');
        $_plan->();
    };
    $_ok->('subtest passed');

    # returns
    ok 1 - yay!
    not ok 2 - boo :(
        ok 1 - thing 1 good
        ok 2 - thing 2 good
        ok 3 - thing 3 good
        ok 4 # skip over there
        1..4
    ok 3 - subtest passed

=cut

sub counters {
    my $level = shift @_ || 0;
    $level *= 4;
    my $i = 0;

    my $indent = !$level ? q{} : (' ' x $level);

    return (
        sub { $indent .     'ok ' . ++$i . " - $_[0]"      },
        sub { $indent . 'not ok ' . ++$i . " - $_[0]"      },
        sub { $indent .     'ok ' . ++$i . " # skip $_[0]" },
        sub { $indent . "1..$i"                            },
        sub { "$_[0] # TODO $_[1]"                         },
        sub { $indent . "$_[0]"                            },
    );
}

!!42;
__END__

=for stopwords SUBTESTS subtests Subtests subtest Subtest

=head1 SYNOPSIS

    use TAP::SimpleOutput 'counter';

    my ($_ok, $_nok, $_skip, $_plan) = counters();
    say $_ok->('TestClass has a metaclass');
    say $_ok->('TestClass is a Moose class');
    say $_ok->('TestClass has an attribute named bar');
    say $_ok->('TestClass has an attribute named baz');
    do {
        my ($_ok, $_nok, $_skip, $_plan) = counters(1);
        say $_ok->(q{TestClass's attribute baz does TestRole::Two});
        say $_ok->(q{TestClass's attribute baz has a reader});
        say $_ok->(q{TestClass's attribute baz option reader correct});
        say $_plan->();
    };
    say $_ok->(q{[subtest] checking TestClass's attribute baz});
    say $_ok->('TestClass has an attribute named foo');

    # STDOUT looks like:
    ok 1 - TestClass has a metaclass
    ok 2 - TestClass is a Moose class
    ok 3 - TestClass has an attribute named bar
    ok 4 - TestClass has an attribute named baz
        ok 1 - TestClass's attribute baz does TestRole::Two
        ok 2 - TestClass's attribute baz has a reader
        ok 3 - TestClass's attribute baz option reader correct
        1..3
    ok 5 - [subtest] checking TestClass's attribute baz
    ok 6 - TestClass has an attribute named foo


=head1 DESCRIPTION

We provide one function, C<counters()>, that returns a number of simple
closures designed to help output TAP easily and correctly, with a minimum of
fuss.

=head1 USAGE WITH Test::Builder::Tester

This package was created from code I was using to make it easier to test my
test packages with L<Test::Builder::Tester>:

    test_out $_ok->('TestClass has a metaclass');
    test_out $_ok->('TestClass is a Moose class');
    test_out $_ok->('TestClass has an attribute named bar');
    test_out $_ok->('TestClass has an attribute named baz');

Once I realized I was using the exact same code (perhaps at different points
in time) in multiple packages, the decision to break it out became pretty
easy to make.

=head1 SUBTESTS

Subtest formatting can be done by passing a an integer "level" parameter to
C<counter()>; see the function's documentation for details.

=head1 SEE ALSO

L<Test::Builder::Tester>
L<TAP::Harness>

=cut
