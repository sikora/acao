package Acao::View::Download::CSV;

# Copyright 2010 - Prefeitura Municipal de Fortaleza
#
# Este arquivo é parte do programa Ação - Sistema de Acompanhamento de
# Projetos Sociais
#
# O Ação é um software livre; você pode redistribui-lo e/ou modifica-lo
# dentro dos termos da Licença Pública Geral GNU como publicada pela
# Fundação do Software Livre (FSF); na versão 2 da Licença.
#
# Este programa é distribuido na esperança que possa ser util, mas SEM
# NENHUMA GARANTIA; sem uma garantia implicita de ADEQUAÇÂO a qualquer
# MERCADO ou APLICAÇÃO EM PARTICULAR. Veja a Licença Pública Geral GNU
# para maiores detalhes.
#
# Você deve ter recebido uma cópia da Licença Pública Geral GNU, sob o
# título "LICENCA.txt", junto com este programa, se não, escreva para a
# Fundação do Software Livre(FSF) Inc., 51 Franklin St, Fifth Floor,
use strict;
use warnings;
use utf8;

=head1 NAME

Acao::View::Download::CSV - Renderiza documentos CSV.

=head1 DESCRIPTION

Essa view é utilizada para enviar ao usuário um documento csv que está
no stash sob a chave "csv".

=cut

use base qw( Catalyst::View::Download::CSV );

__PACKAGE__->config(			
    'quote_char' => '"',
    'escape_char' => '"',
    'sep_char' => ";",
    'eol' => "\n",
    'binary' => 1,
	 'allow_loose_quotes' => 1,
	 'allow_loose_escapes' => 1,
	 'allow_whitespace' => 1,
	 'always_quote' => 1
);

=head1 COPYRIGHT AND LICENSING

Copyright 2010 - Prefeitura de Fortaleza. Este software é licenciado
sob a GPL versão 2.

=cut

1;
