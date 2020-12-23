#!/usr/bin/perl
use strict;
package db;
use utf8;

use DBIx::Array;
use DBIx::Simple;
use DBIx::Struct;

use Data::Dumper;

sub new {
    my ($class) = @_;
    
    my $dbs = DBIx::Simple->connect( "DBI:mysql:"."cdata".":"."localhost", "cdata","cdata",
        { mysql_enable_utf8 => 1, PrintError => 1, mysql_client_found_rows => 1, mysql_auto_reconnect => 1 }
    );

    my $dba = DBIx::Array->new(dbh=>$dbs->dbh);

    my $self = {
        dbs => $dbs,
        dba => $dba
    };

    bless $self, $class;
    return $self;
}

sub SELECT {
    my ($self, $str) = @_;
    
    $str->{columns}     = defined $str->{columns} ? $str->{columns} : '*';
    $str->{where}       = defined $str->{where} ? "WHERE $str->{where}" : '';
    $str->{ORDER_BY}    = defined $str->{ORDER_BY} ? "ORDER BY $str->{ORDER_BY}" : '';
    $str->{LEFT_JOIN}   = defined $str->{LEFT_JOIN} ? "LEFT JOIN $str->{LEFT_JOIN}" : '';
    $str->{GROUP_BY}    = defined $str->{GROUP_BY} ? "GROUP BY $str->{GROUP_BY}" : '';

    if ($str->{method} eq 'group_hashes') {
        return $self->{'dbs'}->query("SELECT $str->{columns} FROM $str->{table_name}")->group_hashes($str->{group_hashes});
    }
    elsif ($str->{method} eq 'exists') {
        return $self->{'dbs'}->query("SELECT EXISTS(SELECT $str->{columns} FROM $str->{table_name} $str->{where})")->list;
    }  
    else {
        my $data = $self->{'dba'}->sqlarrayhash("SELECT $str->{columns} FROM $str->{table_name} $str->{where} $str->{LEFT_JOIN} $str->{ORDER_BY} $str->{GROUP_BY}"); 
        return $data;
    }
}

sub INSERT {
    my ($self, $str) = @_;
    return $self->{'dbs'}->query("INSERT INTO $str->{table_name} VALUES($str->{values});");
}

sub CREATE {
    my ($self, $str) = @_;
    return $self->{'dbs'}->query("CREATE TABLE $str->{table_name} ($str->{columns})");
}

sub UPDATE {
    my ($self, $str) = @_;
    return $self->{'dbs'}->query("UPDATE $str->{table_name} SET $str->{set} WHERE $str->{where}");
}

# sub DELETE {}

1;


=pod

if (defined $str->{columns}){return $dbh->selectall_arrayref("SELECT $str->{columns} FROM $str->{table_name}", { Slice => {} });} elsif (defined $str->{where}){} else {return $dbh->selectall_arrayref("SELECT * FROM $str->{table_name}", { Slice => {} });}
