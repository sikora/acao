package Acao::View::ZIP;
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

	$c->res->content_type("application/zip");
	$c->res->header( 'Content-Disposition' => "filename=" . $c->stash->{filename} );
	$c->res->output($c->stash->{zip});
}

1;
