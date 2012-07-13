package Acao::View::PDF;
use strict;
use warnings;
use utf8;

use base 'Catalyst::View';

=head1 NAME

Acao::View::PDF - Catalyst View

=head1 DESCRIPTION

Catalyst View.

=head1 AUTHOR

Arthur,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

sub process {
	my($self, $c) = @_;

	$c->res->content_type("application/pdf");
	$c->res->output($c->stash->{pdf});
}

1;
