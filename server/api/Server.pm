#!/usr/bin/perl
package server;

BEGIN { 
    use FindBin qw($Bin);
    our $libpath = $Bin . '/..';
    eval { do "$libpath/config.pl" };
    our %conf;

    unshift (@INC, './',
        $libpath . '/db',
        $libpath . '/query', 
        $libpath . '/log'
    );
};

use strict;
use warnings;

use Mojolicious::Lite -signatures; 
use Mojo::AsyncAwait;

use Log;
use Query;
use JSON;

use db; my $db = db->new();

app->config(
    hypnotoad => {
        listen => [ 'http://*:7890/' ],
        workers => 5
    }
);

under '/api';

get '/onu/onu-list' => async sub {
    my ( $c ) = @_;
    my $ip = $c->param('ip');
    eval {
        return $c->render(json => get_onu_list($ip));
    };
    if ($@) {
        Log->_error(["($$)", $@]);
        $c->render(status => 500, text => $@); 
    }
};

get '/onu/history' => async sub {
    my ( $c ) = @_;
    my $ip = $c->param('ip');
    my $port = $c->param('port');
    eval { 
        $c->render(json => $db->SELECT({
            table_name => 'history_' . $ip,
            where => 'port =' . $port
        }))
    };
    if ($@) {
        Log->_error(["($$)", $@]);
        $c->render(status => 500, text => $@); 
    }
};

get '/onu/update-data' => async sub {
    my ( $c ) = @_;
    my $ip = $c->param('ip');
    my $port = $c->param('port');
    Query->Update($ip, $port);
};

get '/switch/switch-list' => async sub {
    my ( $c ) = @_;
    eval { 
        $c->render(json => $db->SELECT({table_name => 'olt'}))
    };
    if ($@) {
        Log->_error(["($$)", $@]);
        $c->render(status => 500, text => $@); 
    }
};

get '/switch/update-data' => sub {
    my ( $c ) = @_;
    my $ip = $c->param('ip');
    eval {
        Query->Update($ip);
        $c->render(status => 200);
    }; 
    if ($@) {
        Log->_error(["($$)", $@]);
        $c->render(status => 500, text => $@); 
    } else { 
        # Log->_acces(["Выполнено ручное обновление " . _bin2ip($ip)), "pid: ($$)"]);
        $c->render(status => 200);
    }
};

post '/change-onu-data' => sub {
    my ( $c ) = @_;
    eval {
        post_change_onu_data($c->req->body);
    }; if ($@) {
        $c->render(status => 500, text => $@); 
        Log->_error(["($$)", $@]);
    }
};

post '/switch-add' => sub {
    my ( $c ) = @_;
    return post_switch_add($c->req->body);
};

app->start;

sub get_onu_list {
    my $ip = shift;
    return $db->SELECT({ 
        table_name  => 'history_' . $ip, 
        columns     => "olt_$ip.port, mac, max(date), address, power, voltage, temperature, area, serial_number",
        LEFT_JOIN   => "olt_$ip ON olt_$ip.port = history_$ip.port",
        GROUP_BY    => 'olt_' . $ip . '.port'
    })
};

sub post_change_onu_data {
    my ($attr) = @_;
    $attr = decode_json $attr;
    return (
        $db->UPDATE({
            table_name  => 'olt_' . $attr->{ip},
            set => "
                address = '$attr->{address}', 
                serial_number = '$attr->{serial_number}', 
                mac = '$attr->{mac}', 
                area = '$attr->{area}'
            ",  
            where => "port =" . $attr->{port}
        })
    )
};

sub post_switch_add {
    my $attr = shift;
    $attr = decode_json $attr;
    $attr->{ip} = unpack("N",pack("C4",split(/\./,$attr->{ip})));
    return (
        $db->INSERT({
            table_name  => 'olt',
            values      => qq(
                '$attr->{ip}', 
                '$attr->{name}', 
                '$attr->{vendor}', 
                '$attr->{model}', 
                '', 
                ''
            )
        }),
        $db->CREATE({
            table_name  => qq(olt_$attr->{ip}),
            columns     => q(
                port int(11), 
                mac varchar(50), 
                address varchar(50), 
                area varchar(50), 
                serial_number 
                varchar(100)
            ) 
        }),
        $db->CREATE({
                table_name  => qq(history_$attr->{ip}),
                columns     => qq(
                    port int(11), 
                    date DATETIME, 
                    power FLOAT, 
                    voltage FLOAT, 
                    temperature FLOAT
                )
            }
        )
    );
};

sub _bin2ip {
    my ( $ip ) = @_;
    return join(".",unpack("C4",pack("N",$ip)))
};