#!/usr/bin/perl
package Log;

use strict;
use warnings;
use POSIX qw(strftime);
use FindBin qw($Bin);
my $time = localtime;

my $file_error = "$Bin/error.log";
my $file_acces = "$Bin/acces.log";

sub _error {
    my ($self, $attr) = @_;
    open( my $fh, '>>', $file_error) ;
    print $fh "$time @$attr\n";
    close $fh;
}

sub _acces {
    my ($self, $attr) = @_;
    open( my $fh, '>>', $file_acces) ;
    print $fh "$time @$attr\n";
    close $fh;
}
1;