package Acao::Model::Volume;

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
use Moose;
extends 'Acao::Model';
use Acao::ModelUtil;
use XML::LibXML;
use XML::Compile::Schema;
use XML::Compile::Util;
use DateTime;
use utf8;
use Encode;
use Data::UUID;
use Data::Dumper;
use List::MoreUtils 'pairwise';


with 'Acao::Role::Model::Indices';


use constant VOLUME_NS => 'http://schemas.fortaleza.ce.gov.br/acao/volume.xsd';
my $controle = XML::Compile::Schema->new( Acao->path_to('schemas/volume.xsd') );
$controle->importDefinitions( Acao->path_to('schemas/autorizacoes.xsd') );
$controle->importDefinitions( Acao->path_to('schemas/classificacao.xsd') );
my $controle_w = $controle->compile(
    WRITER                => pack_type( VOLUME_NS, 'volume' ),
    use_default_namespace => 1
);
my $controle_r =
  $controle->compile( READER => pack_type( VOLUME_NS, 'volume' ) );

with 'Acao::Role::Model::Autorizacao' =>
  { xmlcompile => $controle, namespace => VOLUME_NS };
with 'Acao::Role::Model::Classificacao' =>
  { xmlcompile => $controle, namespace => VOLUME_NS, };

my $role_criar   = Acao->config->{'roles'}->{'volume'}->{'criar'};
my $role_alterar = Acao->config->{'roles'}->{'volume'}->{'alterar'};
my $role_listar  = Acao->config->{'roles'}->{'volume'}->{'listar'};
my $role_ver     = Acao->config->{'roles'}->{'volume'}->{'visualizar'};
my $admin_super = Acao->config->{'Model::LDAP'}->{admin_super};
use constant CLASSIFICACOES_NS =>
  'http://schemas.fortaleza.ce.gov.br/acao/classificacao.xsd';
my $controle_class =
  XML::Compile::Schema->new( Acao->path_to('schemas/classificacao.xsd') );
my $controle_class_w = $controle_class->compile(
    WRITER                => pack_type( CLASSIFICACOES_NS, 'classificacao' ),
    use_default_namespace => 1
);

=head1 NAME

Acao::Model::Volume - Implementa as regras de negócio do papel volume

=head1 DESCRIPTION

Essa classe implementa as regras de negócio específicas para o papel
de volume.

=head1 METHODS

=over

=item listar_volumes()

Este método retorna os Volumes os quais o usuário autenticado tem acesso.

=cut

txn_method 'listar_volumes' => authorized $role_listar  => sub {
    my ( $self, $args ) = @_;

    my $grupos = join ' or ',
      map { '@principal = "' . $_ . '"' } @{ $self->user->memberof };

    # Query para listagem
    my $list = 'declare namespace ns = "http://schemas.fortaleza.ce.gov.br/acao/volume.xsd";'
             . 'declare namespace author = "http://schemas.fortaleza.ce.gov.br/acao/autorizacoes.xsd";'
             . 'declare namespace cl = "http://schemas.fortaleza.ce.gov.br/acao/classificacao.xsd";'
             . 'subsequence('
             . 'for $x in collection("volume")/ns:volume[ns:autorizacoes/author:autorizacao[('
             . $grupos . ')'
             . 'and @role="listar"]] '
             . 'let $alterar := count(collection("volume")/ns:volume[ns:collection = $x/ns:collection]/ns:autorizacoes/author:autorizacao[('.$grupos.')'
             . 'and @role = "alterar"])'
             . 'order by $x/ns:nome/text()'
             . 'return ($x/ns:collection/text(), '
             . $args->{xqueryret} . '),' . '('
             . $args->{interval_ini} * $args->{num_por_pagina}
             . ') + 1 ,'
             . $args->{num_por_pagina} . '' . ')';

    # Contrução da query de contagem para contrução da paginação

    my $count = 'declare namespace ns = "http://schemas.fortaleza.ce.gov.br/acao/volume.xsd";'
              . 'declare namespace author = "http://schemas.fortaleza.ce.gov.br/acao/autorizacoes.xsd";'
              . 'count('
              . 'for $x in collection("volume")/ns:volume[ns:autorizacoes/author:autorizacao[('
              . $grupos . ')'
              . 'and @role="listar"]]'
              . 'return "")';

              #&dfdfsgds();

    return {
        list  => $list,
        count => $count
    };

};

=item criar_volume()

Este método realiza a persistencia das informações informadas no processo/ação de criar um novo Volume.

=cut

txn_method 'criar_volume' => authorized $role_criar => sub {
    my $self = shift;
    my ( $nome, $representaVolumeFisico, $classificacao, $localizacao,
        $autorizacoes, $ip )
      = @_;

    my $ug       = new Data::UUID;
    my $uuid     = $ug->create();
    my $str      = $ug->to_string($uuid);
    my $doc_name = 'volume-' . $str;

    my $acao  = 'insert';
    my $dados = 'create collection ("' . $doc_name . '")';
    my $role  = 'role';

    $self->sedna->execute($dados);

    my $doc = XML::LibXML::Document->new( '1.0', 'UTF-8' );

    my $res_xml = $controle_w->(
        $doc,
        {
            nome                   => uc $nome,
            criacao                => DateTime->now()->set_time_zone('America/Fortaleza'),
            fechamento             => '',
            arquivamento           => '',
            collection             => $doc_name,
            estado                 => 'aberto',
            representaVolumeFisico => $representaVolumeFisico,
            classificacoes         => $classificacao,
            localizacao            => $localizacao,
            autorizacoes           => $autorizacoes,

        },
    );

    $self->sedna->conn->loadData( $res_xml->toString, $doc_name, 'volume' );
    $self->sedna->conn->endLoadData();
    return $doc_name;

};

txn_method 'alterar_estado' => authorized $role_alterar => sub {
    my $self = shift;
    my ( $id_volume, $estado, $ip ) = @_;

    my $xq =
'declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/volume.xsd";';
    $xq .=
        'update replace $x in collection("volume")/ns:volume[ns:collection="'
      . $id_volume
      . '"]/ns:estado with <ns:estado>'
      . $estado
      . '</ns:estado> ';
    $self->sedna->execute($xq);

    if ( $estado eq 'fechado' ) {
        my $xq =
'declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/volume.xsd";';
        $xq .=
          'update replace $x in collection("volume")/ns:volume[ns:collection="'
          . $id_volume . '"]';
        $xq .=
            '/ns:fechamento with <ns:fechamento>'
          . DateTime->now()->set_time_zone('America/Fortaleza')
          . '</ns:fechamento>';
        $self->sedna->execute($xq);
    }

    if ( $estado eq 'arquivado' ) {
        my $xq =
'declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/volume.xsd";';
        $xq .=
          'update replace $x in collection("volume")/ns:volume[ns:collection="'
          . $id_volume . '"]';
        $xq .=
            '/ns:arquivamento with <ns:arquivamento>'
          . DateTime->now()->set_time_zone('America/Fortaleza')
          . '</ns:arquivamento>';
        $self->sedna->execute($xq);
        $self->invalidate_indices($id_volume);
    }

    if ( $estado eq 'aberto' ) {
        my $xq =
'declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/volume.xsd";';
        $xq .=
          'update replace $x in collection("volume")/ns:volume[ns:collection="'
          . $id_volume . '"]';
        $xq .= '/ns:arquivamento with <ns:arquivamento></ns:arquivamento>';
        $self->sedna->execute($xq);

        $xq =
'declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/volume.xsd";';
        $xq .=
          'update replace $x in collection("volume")/ns:volume[ns:collection="'
          . $id_volume . '"]';
        $xq .= '/ns:fechamento with <ns:fechamento></ns:fechamento>';
        $self->sedna->execute($xq);
        $self->revalidate_indices($id_volume);
    }

};

=item getDadosVolumeId()

Este método retona os Dados de um Volume.

=cut

txn_method 'getDadosVolumeId' => authorized $role_listar => sub {
    my $self = shift;
    my ( $id_volume, $assuntos_dn, $local_dn ) = @_;

    my $xq = q|declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/volume.xsd";
              declare namespace cl="http://schemas.fortaleza.ce.gov.br/acao/classificacao.xsd";
              for $x in collection("volume")/ns:volume[ns:collection="|. $id_volume . q|"]
                 return (concat($x/ns:nome/text()," "),
                    string-join(
                        for $c in $x/ns:classificacoes/cl:classificacao/text()
                            return (if (ends-with($c,",|.$assuntos_dn.q|")) then (string-join(reverse(for $i in tokenize(substring-before($c,",|.$assuntos_dn.q|"),',')
                                 return (tokenize($i,'='))[2]),' - ')
                               ) else ($c)),', '),
                    string-join(
                        for $d in $x/ns:localizacao/text()
                            return (if (ends-with($d,",|.$local_dn.q|")) then (string-join(reverse(for $j in tokenize(substring-before($d,",|.$local_dn.q|"),',')
                                 return (tokenize($j,'='))[2]),' - ')
                               ) else ($d)),','),
                    concat($x/ns:estado/text()," "),
                    concat($x/ns:criacao/text()," "),
                    concat($x/ns:representaVolumeFisico/text()," "))|;

    $self->sedna->execute($xq);

    my $vol = {};
    while ( my $nome = $self->sedna->get_item ) {
        $vol = {
            nome           => $nome,
            classificacoes => $self->sedna->get_item,
            localizacao    => $self->sedna->get_item,
            estado         => $self->sedna->get_item,
            criacao        => $self->sedna->get_item,
            volume_fisico  => $self->sedna->get_item > 0 ? 'Sim' : 'Não',
        };

    }

    if ($id_volume) {
        $xq = 'count(collection("'. $id_volume . '"))';
        my $qtdePront = 0;
        $self->sedna->execute($xq);
        $qtdePront = $self->sedna->get_item;
        $vol->{qtd_prontuarios} = $qtdePront;
    }
    return $vol;
};

=item options_volumes()

Esté método retorna uma lista de 'options', tags html, com nomes dos Volumes
nos quais os mesmos possuem autorização.

=cut

txn_method 'options_volumes' => authorized $role_alterar => sub {
    my ( $self, $volume_origem ) = @_;

    my $grupos = join ' or ',
      map { '@principal = "' . $_ . '"' } @{ $self->user->memberof };

    my $xq =
'declare namespace vol = "http://schemas.fortaleza.ce.gov.br/acao/volume.xsd";
              declare namespace author = "http://schemas.fortaleza.ce.gov.br/acao/autorizacoes.xsd";
              for $x in collection("volume")/vol:volume[vol:autorizacoes/author:autorizacao[('
      . $grupos . ')
                 and @role="criar"]][vol:collection/text() ne "'
      . $volume_origem . '"]
                     return <option value="{$x/vol:collection/text()}">{$x/vol:nome/text()}</option>';

    $self->sedna->execute($xq);
    my $ret;
    while ( my $item = $self->sedna->get_item() ) {
        $ret .= $item;
    }
    return $ret;
};

=item pode_ver_volume()

Esté método realiza a validação de autorização, verificando se o
user logado pode lista os volume específico

=cut

sub pode_listar_volume {
    my ( $self, $id_volume ) = @_;
    my $grupos = join ' or ',
      map { '@principal = "' . $_ . '"' } @{ $self->user->memberof };

    $self->sedna->begin;
    my $query =
'declare namespace ns = "http://schemas.fortaleza.ce.gov.br/acao/volume.xsd";'
      . 'declare namespace author = "http://schemas.fortaleza.ce.gov.br/acao/autorizacoes.xsd";'
      . 'for $x in collection("volume")/ns:volume[ns:collection = "'
      . $id_volume . '"] '
      . 'where $x/ns:autorizacoes/author:autorizacao[('
      . $grupos
      . ') and @role="listar"] '
      . 'return $x/ns:autorizacoes';

    $self->sedna->execute($query);
    my $res = $self->sedna->get_item();
    $self->sedna->commit;
    return $res;
}
=item nega_acesso_aba_autorizacoes()

=cut

sub nega_acesso_aba_autorizacoes {
    my ( $self, $id_volume ) = @_;
    return 
    $self->_checa_autorizacao_volume( $id_volume, 'NaoModificaAutorizacoes' )
      && $role_ver ~~ @{ $self->user->memberof };

}

=item nega_acesso_aba_localizacao()

=cut

sub nega_acesso_aba_localizacao {
    my ( $self, $id_volume ) = @_;
    return 
    $self->_checa_autorizacao_volume( $id_volume, 'NaoModificaLocalizacao' )
      && $role_ver ~~ @{ $self->user->memberof };

}

=item nega_acesso_aba_classificacao()

=cut

sub nega_acesso_aba_classificacao {
    my ( $self, $id_volume ) = @_;
    return 
    $self->_checa_autorizacao_volume( $id_volume, 'NaoModificaClassificacao' )
      && $role_ver ~~ @{ $self->user->memberof };

}
=item pode_criar_volume()

Esté método realiza a validação de autorização, verificando se o
user logado pode CRIAR Volumes

=cut

sub pode_criar_volume {
    my ($self) = @_;
    return $admin_super ~~ @{$self->user->memberof} ||
    $role_criar ~~ @{ $self->user->memberof };

}

=item pode_alterar_volume()

Esté método realiza a validação de autorização, verificando se o
user logado pode ALTERAR Volume(s)

=cut

sub pode_alterar_volume {
    my ( $self, $id_volume ) = @_;
    return $admin_super ~~ @{$self->user->memberof} ||
    $self->_checa_autorizacao_volume( $id_volume, 'alterar' )
      && $role_alterar ~~ @{ $self->user->memberof };
}

=item pode_ver_volume()

Esté método realiza a validação de autorização, verificando se o
user logado pode VER o conteúdo do Volume

=cut

sub pode_ver_volume {
    my ( $self, $id_volume ) = @_;
    return $admin_super ~~ @{$self->user->memberof} ||
    $self->_checa_autorizacao_volume( $id_volume, 'visualizar' )
      && $role_ver ~~ @{ $self->user->memberof };

}

=item classificacoes_do_volume()

Este método retona um XML das Classificações do Volume

=cut

sub classificacoes_do_volume {
    my ( $self, $id_volume ) = @_;

    $self->sedna->begin;
    my $query =
'declare namespace ns = "http://schemas.fortaleza.ce.gov.br/acao/volume.xsd";'
      . 'declare namespace cl = "http://schemas.fortaleza.ce.gov.br/acao/classificacao.xsd";'
      . 'for $x in collection("volume")/ns:volume[ns:collection = "'
      . $id_volume . '"] '
      . 'return $x/ns:classificacoes';

    $self->sedna->execute($query);
    my $xml = $self->sedna->get_item();
    $self->sedna->commit;
    return $xml;

}

=item store_altera_volume()

Este método realiza a persistencia das alterações realizadas no Volume.

=cut

sub store_altera_volume {
    my ( $self, $args ) = @_;

    # Gambis provisória -  Fazendo Update de cada campo separadamente!
    my $query_autorizacao =
'declare namespace ns = "http://schemas.fortaleza.ce.gov.br/acao/volume.xsd";'
      . 'update replace $x in collection("volume")'
      . '[/ns:volume/ns:collection="'
      . $args->{id_volume}
      . '"]/ns:volume/ns:autorizacoes'
      . ' with '
      . $args->{autorizacoes};
    $self->sedna->begin;
    $self->sedna->execute($query_autorizacao);

    my $query_nome =
'declare namespace ns = "http://schemas.fortaleza.ce.gov.br/acao/volume.xsd";'
      . 'update replace $x in collection("volume")'
      . '[/ns:volume/ns:collection="'
      . $args->{id_volume}
      . '"]/ns:volume/ns:nome'
      . ' with <nome xmlns="http://schemas.fortaleza.ce.gov.br/acao/volume.xsd">'
      . $args->{nome}
      . '</nome>';
    $self->sedna->execute($query_nome);

    my $query_classificacoes =
'declare namespace ns = "http://schemas.fortaleza.ce.gov.br/acao/volume.xsd";'
      . 'declare namespace cl = "http://schemas.fortaleza.ce.gov.br/acao/classificacao.xsd";'
      . 'update replace $x in collection("volume")'
      . '[/ns:volume/ns:collection="'
      . $args->{id_volume}
      . '"]/ns:volume/ns:classificacoes'
      . ' with '
      . $args->{classificacoes};
    $self->sedna->execute($query_classificacoes);

    my $query_volume_fisico =
'declare namespace ns = "http://schemas.fortaleza.ce.gov.br/acao/volume.xsd";'
      . 'update replace $x in collection("volume")'
      . '[/ns:volume/ns:collection="'
      . $args->{id_volume}
      . '"]/ns:volume/ns:representaVolumeFisico'
      . ' with <representaVolumeFisico xmlns="http://schemas.fortaleza.ce.gov.br/acao/volume.xsd">'
      . $args->{volume_fisico}
      . '</representaVolumeFisico>';
    $self->sedna->execute($query_volume_fisico);

    my $query_localizacao =
'declare namespace ns = "http://schemas.fortaleza.ce.gov.br/acao/volume.xsd";'
      . 'update replace $x in collection("volume")'
      . '[/ns:volume/ns:collection="'
      . $args->{id_volume}
      . '"]/ns:volume/ns:localizacao'
      . ' with <localizacao xmlns="http://schemas.fortaleza.ce.gov.br/acao/volume.xsd">'
      . $args->{localizacao}
      . '</localizacao>';
    $self->sedna->execute($query_localizacao);

    $self->sedna->commit;

    $self->update_autorizacoes_vol($args->{id_volume},$self->desserialize_autorizacoes($args->{autorizacoes}));

}

sub localizacao_do_volume {
    my $self = shift;
    my ($id_volume) = @_;

    my $xq =
q|declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/volume.xsd";
             declare namespace cl="http://schemas.fortaleza.ce.gov.br/acao/classificacao.xsd";
             for $x in collection("volume")/ns:volume[ns:collection="|
      . $id_volume . q|"]
             return $x/ns:localizacao/text()|;

    $self->sedna->begin;
    $self->sedna->execute($xq);
    my $local = $self->sedna->get_item;
    $self->sedna->commit;
    return $local;
}

sub buscar_no_indice {
    my $self = shift;
    my $hashClause = shift;
    return $self->find_for_index($hashClause);
}

sub find_key_indexes {
  my ($self, $c) = @_;
  my $classificacao;
  my @indexes;
  my $grupos = join ' or ', map { '@principal = "' . $_ . '"' } @{ $self->user->memberof };

# Query para listagem
  my $list = 'declare namespace ns = "http://schemas.fortaleza.ce.gov.br/acao/volume.xsd";'
    . 'declare namespace author = "http://schemas.fortaleza.ce.gov.br/acao/autorizacoes.xsd";'
    . 'declare namespace cl = "http://schemas.fortaleza.ce.gov.br/acao/classificacao.xsd";'
    . 'for $x in collection("volume")/ns:volume[ns:autorizacoes/author:autorizacao[('
    . $grupos . ')'
    . 'and @role="listar"]] '
    . 'return $x/ns:classificacoes/cl:classificacao/text()';

  $self->sedna->begin;
  $self->sedna->execute($list);

  my $clause;

  while (my $cn = $self->sedna->get_item)  {
    $cn =~ s/\n//o;
    $cn =~ s/^.*?(cn=.*?),dc.*/$1/gso;
    $clause .= '$x/cl:classificacao="'.$cn.'" or ';
  }

  my $length = length $clause;
  $clause = substr $clause, 0, $length-4;
  $self->sedna->commit;

  #my $xq_indexes = qq|declare namespace cl = "http://schemas.fortaleza.ce.gov.br/acao/classificacao.xsd";
  #      declare namespace idx = "http://schemas.fortaleza.ce.gov.br/acao/indexhint.xsd";
  #      for \$x in collection("acao-schemas")/*/*/*/*/cl:classificacoes
  #      where $clause
  #      return \$x/../../../../*/*/*/idx:index/idx:hint/\@key/string()|;
  my $xq_indexes = 'declare namespace cl = "http://schemas.fortaleza.ce.gov.br/acao/classificacao.xsd";
        declare namespace idx = "http://schemas.fortaleza.ce.gov.br/acao/indexhint.xsd";
        for $x in distinct-values(collection("acao-schemas")//@key/string())
        return $x';

  $self->sedna->begin;
  $self->sedna->execute($xq_indexes);

  while (my $item=$self->sedna->get_item ) {
          $item =~ s/^\s+//;
        $item =~ s/\s+$//;
    push(@indexes, $item);
  }
  $self->sedna->commit;
  return @indexes;
}

sub reindexa {
    my $self = shift;
    my ($id_volume) = @_;
    $self->reindexar($id_volume);
}

sub get_estado_volume {
    my $self = shift;
    my ($id_volume) = @_;
    my $xquery = 'declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/volume.xsd";
                  declare namespace cl="http://schemas.fortaleza.ce.gov.br/acao/classificacao.xsd";
                    for $x in collection("volume")/ns:volume[ns:collection="'.$id_volume.'"]
                        return $x/ns:estado/text()';
    $self->sedna->begin;
    $self->sedna->execute($xquery);
    my $estado = $self->sedna->get_item();
    $self->sedna->commit;
    return $estado;
}

=cut

=item

=cut

=head1 COPYRIGHT AND LICENSING

Copyright 2010 - Prefeitura de Fortaleza. Este software é licenciado
sob a GPL versão 2.

=cut

42;
