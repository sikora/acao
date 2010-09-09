package Acao::Controller::Public::Ldap;

use strict;
use warnings;
use parent 'Catalyst::Controller';

sub base : Chained('/') : PathPart('ldap') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
}

sub principal :Chained('base') :PathPart('') : Args(0) {
    my ( $self, $c) = @_;
    my $mesg = $c->model('Ldap')->search('(cn=VIRGO)');
    my @entries = $mesg->entries;
  #  warn $entries[0]->sn;
}

1;