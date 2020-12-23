#!/usr/bin/perl
package Query;

use strict;
use warnings;

BEGIN { 
    use FindBin qw($Bin);
    our $libpath = $Bin . '/..';
    eval { do "$libpath/config.pl" };
    our %conf;

    unshift (@INC,
        $libpath . '/db', 
        $libpath . '/log'
    );
};

use FindBin qw($Bin);
use Data::Dumper;
use POSIX qw(strftime);
use db;
use Log;

our (%DB_COLUMN, %DB_CONFIG);

my $db = db->new();

matching() if not caller;

sub Session { 
    use Net::SNMP qw(:snmp);
    my ($attr) = @_;
    my $Session = Net::SNMP->session(
        -hostname => $attr->{ip_address}, 
        -community => 'public', 
        -version => 'snmpv2c'
    );
    return $Session;
}

sub OIDS {
    return {
        'Cdata' => [
            {
                'model'         => 'FD1612S',
                'mac'           => '1.3.6.1.4.1.17409.2.3.4.1.1.7',
                'power'         => '1.3.6.1.4.1.17409.2.3.4.2.1.4',
                'temperature'   => '1.3.6.1.4.1.17409.2.3.4.2.1.8',
                'voltage'       => '1.3.6.1.4.1.17409.2.3.4.2.1.7'
            }
        ],
        'BDCOM' => [
            {
                'model' => 'P3310C-AC'
            }
        ]
    }
}

sub matching {
    my $DecodeApi = &OIDS;
    my $SwitchList = $db->SELECT({
        table_name  => $DB_CONFIG{MASTER_OLT}, 
        columns     => qq(
            $DB_COLUMN{VENDOR}, $DB_COLUMN{MODEL}, $DB_COLUMN{IP_ADDRESS}, $DB_COLUMN{COMMUNITY}
        ),
        method      => 'group_hashes',
        group_hashes=> $DB_COLUMN{VENDOR}
    });


    for my $Vendor (keys %{$SwitchList}) {
        for my $Values (values @{%{$SwitchList}->@{$Vendor}}) {
            if (exists $Values->{$DB_COLUMN{IP_ADDRESS}}) {
                if (grep {$Vendor eq $_} keys %{$DecodeApi}) {
                    my $Session = Session({$DB_COLUMN{IP_ADDRESS} => $Values->{$DB_COLUMN{IP_ADDRESS}}});
                    ChoiceSwitch($Session, @{$DecodeApi->{$Vendor}},
                        { 
                            $DB_COLUMN{VENDOR} => $Vendor, 
                            $DB_COLUMN{IP_ADDRESS} => $Values->{$DB_COLUMN{IP_ADDRESS}},
                            method => 'cron' 
                        }
                    );   
                }
            }
        }
    }
}

sub Update {
    my ($self, $Ip, $Port) = @_; 
    my $DecodeApi = &OIDS;
    my $Data = $db->SELECT(
        { 
            table_name => 'olt', 
            columns => qq(vendor, model, community),
            where => qq(ip_address = $Ip)
        }
    );
    my $Session = Session({ip_address => $Ip});
    my $Vendor = sub { for (@{$Data}) {return $_->{vendor}}};
    my $attr = {
        vendor => &$Vendor, 
        ip_address => $Ip,  
    };
    if (!$Port) {
        $attr->{method} = "update-data-olt";
    } else {
        $attr->{port} = $Port;
        $attr->{method} = "update-data-onu";
    }
    ChoiceSwitch($Session, @{$DecodeApi->{&$Vendor}}, $attr);
}

sub ChoiceSwitch {
    my ($Session, $OIDS, $Params) = @_;
    if ($Params->{vendor} eq 'Cdata') {
        Log->_acces([$Session 
            ? "[$Params->{method}] Соединение уставновлено, обновление данных" 
            : "[$Params->{method}] Ошибка соединения", _bin2ip($Params->{ip_address})
        ]); Cdata($Session, $OIDS, $Params);
    } elsif ($Params->{vendor} eq 'BDCOM') {
        Log->_acces([$Session 
            ? "[$Params->{method}] Соединение уставновлено, обновление данных" 
            : "[$Params->{method}] Ошибка соединения", _bin2ip($Params->{ip_address})
        ]); BDCOM($Session, $OIDS, $Params);
    } 
}

sub Cdata {
    my ($Session, $OIDS, $Params) = @_;

    my $Power = _cdata_convert_power(
        _Cdata_snmpwalk($OIDS, $Session, {params => $DB_COLUMN{POWER}})
    ); Log->_acces(["[$Params->{method}]\t | Ур. сигнала\t", !$Power ? "ERROR" : "OK"]);

    my $Voltage = _cdata_convert_voltage(
        _Cdata_snmpwalk($OIDS, $Session, {params => $DB_COLUMN{VOLTAGE}})
    ) ;Log->_acces(["[$Params->{method}]\t | Напряжение\t", !$Voltage ? "ERROR" : "OK"]);
 
    my $Temperature = _cdata_convert_temperature(
        _Cdata_snmpwalk($OIDS, $Session, {params => $DB_COLUMN{TEMPERATURE}})
    ); Log->_acces(["[$Params->{method}]\t | Температура\t", !$Temperature ? "ERROR" : "OK"]);

    my $MAC = _bin2mac(
        _Cdata_snmpwalk($OIDS, $Session, {params => $DB_COLUMN{MAC}})
    ); Log->_acces(["[$Params->{method}]\t | МAC адреса\t", !$MAC ? "ERROR" : "OK"]);

    my $date = strftime "%F %X", localtime;
    if ($Params->{method} eq 'update-data-onu') {
        $db->INSERT({table_name => $DB_CONFIG{OLT_HISTORY} . $Params->{$DB_COLUMN{IP_ADDRESS}}, 
            values => qq(
                $Params->{$DB_COLUMN{PORT}}, '$date', '$Power->{$Params->{$DB_COLUMN{PORT}}}', 
                '$Voltage->{$Params->{$DB_COLUMN{PORT}}}', '$Temperature->{$Params->{$DB_COLUMN{PORT}}}'
            )
        });
    }
    elsif ($Params->{method} eq 'cron' || 'update-data-olt') {
        for my $PortItem (sort keys %{$MAC}) {
            my $db_result = $db->SELECT({
                table_name => $DB_CONFIG{MAIN_OLT} . $Params->{$DB_COLUMN{IP_ADDRESS}}, 
                where   => "$DB_COLUMN{PORT} = $PortItem",
                method  => 'exists',
                columns => $DB_COLUMN{PORT},
            });
            if ($db_result == 0) {
                eval {
                    $db->INSERT({
                        table_name => $DB_CONFIG{MAIN_OLT} . $Params->{$DB_COLUMN{IP_ADDRESS}}, 
                        values => qq($PortItem, '$MAC->{$PortItem}', '', '', '')
                    });
                    $db->INSERT({
                        table_name => $DB_CONFIG{OLT_HISTORY} . $Params->{$DB_COLUMN{IP_ADDRESS}},
                        values => qq(
                            $PortItem, '$date', '$Power->{$PortItem}', 
                            '$Voltage->{$PortItem}', '$Temperature->{$PortItem}'
                        )
                    }); 
                }; 
                if ($@){
                    Log->_error(["[$Params->{method}]\t $@"]);
                    exit
                }
            } 
            else  {
                eval {
                    $db->INSERT({
                        table_name => "$DB_CONFIG{OLT_HISTORY}$Params->{$DB_COLUMN{IP_ADDRESS}}",
                        values => qq(
                            $PortItem, '$date', '$Power->{$PortItem}',
                            '$Voltage->{$PortItem}', '$Temperature->{$PortItem}'
                        )
                    });
                };
                if ($@){
                    Log->_error(["[$Params->{method}]\t $@"]);
                    exit
                }
            }
        }
    }
   
    sub _Cdata_snmpwalk {
        my ($OID, $Session, $attr ) = @_;
        return $Session->get_table(-baseoid => $OID->{$attr->{params}})
    }

    sub _cdata_convert_voltage {
        my ($voltage) = @_;
        $voltage = {
            map { 
                m/(1678\d+)/sm, 
                sprintf "%.1f", 
                $voltage->{$_} * 0.00001
            } keys %{$voltage} 
        };
        return $voltage;
    }

    sub _cdata_convert_temperature {
        my ($temperature) = @_;
        $temperature = {
            map { 
                m/(1678\d+)/sm, 
                sprintf "%.1f", 
                $temperature->{$_} / 256 
            } keys %{$temperature} 
        };
        return $temperature;
    }

    sub _cdata_convert_power {
        my ($power) = @_;
        $power = {
            map { 
                m/(1678\d+)/sm, 
                sprintf "%.1f", 
                $power->{$_} / 100 
            } keys %{$power} 
        };
        return $power;
    }

    sub _bin2mac {
        my ($mac) = @_;
        my $mm = {};
        for (keys %{$mac}) {
            next unless $_ =~ m/(1678\d+)/sm;
            my $num_key = $1;
            $mac->{$_} =~ s/^0x(.*)/$1/g;
            $mm->{$num_key} = join( ':', unpack( 'A2A2A2A2A2A2', $mac->{$_}));
        }
        return $mm;
    }   
}

sub BDCOM {
    my ($Session, $OIDS, $Params) = @_;
    
}

#**********************************************************************

sub _bin2ip {
    my ( $ip ) = @_;
    return join(".",unpack("C4",pack("N",$ip)))
}

1;
