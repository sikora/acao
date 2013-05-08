package Acao::Model::Dossie;

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
use XML::Simple;

with 'Acao::Role::Model::BuscaXSD';
with 'Acao::Role::Model::Indices';

use constant DOSSIE_NS => 'http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd';
my $controle = XML::Compile::Schema->new( Acao->path_to('schemas/dossie.xsd') );
$controle->importDefinitions( Acao->path_to('schemas/documento.xsd') );
$controle->importDefinitions( Acao->path_to('schemas/classificacao.xsd') );
$controle->importDefinitions( Acao->path_to('schemas/autorizacoes.xsd') );

my $controle_w = $controle->compile(
    WRITER                => pack_type( DOSSIE_NS, 'dossie' ),
    use_default_namespace => 1
);
my $controle_r =
  $controle->compile( READER => pack_type( DOSSIE_NS, 'dossie' ) );

with 'Acao::Role::Model::Autorizacao' =>
  { xmlcompile => $controle, namespace => DOSSIE_NS };
with 'Acao::Role::Model::Classificacao' =>
  { xmlcompile => $controle, namespace => DOSSIE_NS };

my $role_alterar = Acao->config->{'roles'}->{'dossie'}->{'alterar'};

=item  $role_criar
    Role de Criar Dossie
    Informa a DN do LDAP ao qual o membro deve pertencer para CRIAR Dossie.
=cut

my $role_criar  = Acao->config->{'roles'}->{'dossie'}->{'criar'};
my $role_listar = Acao->config->{'roles'}->{'dossie'}->{'listar'};

=item  $role_transferir
    Role de Transferir Dossie entre Volumes.
    Informa a DN do LDAP ao qual o membro deve pertencer para TRANSFERIR Dossie.
=cut

my $role_transferir = Acao->config->{'roles'}->{'dossie'}->{'transferir'};
my $role_ver        = Acao->config->{'roles'}->{'dossie'}->{'visualizar'};
my $admin_super = Acao->config->{'Model::LDAP'}->{admin_super};
=head1 NAME

Acao::Model::Dossie - Implementa as regras de negócio do papel volume

=head1 DESCRIPTION

Essa classe implementa as regras de negócio específicas para o papel
de volume.

=head1 METHODS

=over

=item obter_xsd_dossie()

=cut

txn_method 'obter_xsd_dossie' => authorized $role_listar => sub {
    my ( $self, $dossie ) = @_;
    return $self->sedna->get_document($dossie);
};

=item listar_dossies()

Este método retorna os dossies os quais o usuário autenticado tem acesso.

=cut

txn_method 'listar_dossies' => authorized $role_listar => sub {
    my ( $self, $args ) = @_;

    my $pesquisa = $args->{pesquisa};

    my %ns_base = (
        ns     => "http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd",
        vol    => "http://schemas.fortaleza.ce.gov.br/acao/volume.xsd",
        dc     => "http://schemas.fortaleza.ce.gov.br/acao/documento.xsd",
        author => "http://schemas.fortaleza.ce.gov.br/acao/autorizacoes.xsd",
        cl     => "http://schemas.fortaleza.ce.gov.br/acao/classificacao.xsd"
    );
    my @ns_add =
      map { $args->{pesquisa}{ 'pesquisa_' . $_ . '_ns' } }
      0 .. ( $args->{pesquisa}{numero_campos} - 1 );
    my @ns_add_col =
      map { $args->{pesquisa}{ 'col_' . $_ . '_ns' } }
      0 .. ( $args->{pesquisa}{numero_colunas} - 1 );
    my $counter;
    my $counter_old;
    %ns_base = (%ns_base, map { "col" . $counter_old++ => $_ } @ns_add_col);

    my %ns = ( %ns_base, map { "extra" . $counter++ => $_ } @ns_add );

    my %prefix    = reverse %ns;
    my $declarens = join "\n",
      map { 'declare namespace ' . $_ . '="' . $ns{$_} . '";' } keys %ns;

    my @where;
    
    # Filtrando Prontuários Abertos/fechados
    my $dossieFechadoAberto;
    
    if (($args->{pesquisa}{dossiesAbertos} eq 'on' && $args->{pesquisa}{dossiesFechados} eq 'on') || ($args->{pesquisa}{dossiesAbertos} eq '' && $args->{pesquisa}{dossiesFechados} eq '')) {
        $dossieFechadoAberto =  '';
    } elsif ($args->{pesquisa}{dossiesAbertos} eq 'on'){
        $dossieFechadoAberto = ' [ns:estado/text() eq \'aberto\']  ';    
    } else {    
        $dossieFechadoAberto = ' [(ns:estado/text() eq \'fechado\') or (ns:estado/text() eq \'arquivado\')]  '; 
    }
    ####### 
    if ( $args->{pesquisa}{nome_prontuario} ) {
        push @where, '[contains(upper-case(ns:nome/text()),upper-case('
          . $self->quote_valor( $args->{pesquisa}{nome_prontuario} ) . '))]';
    }
    my $xpprefix = 'ns:doc/dc:documento/dc:documento/dc:conteudo/';
    my $valor_pesquisado;
    foreach my $counter ( 0 .. ( $args->{pesquisa}{numero_campos} - 1 ) ) {
        my $ns     = $args->{pesquisa}{"pesquisa_${counter}_ns"};
        my $prefix = $prefix{$ns};
        $valor_pesquisado = $args->{pesquisa}{"valor_pesquisado_${counter}"};
        $valor_pesquisado =~ s/^\s+//;
	    $valor_pesquisado =~ s/\s+$//;
        my $expr = $self->produce_expr_xpfilter(
            $prefix,
            $args->{pesquisa}{"campo_formulario_${counter}"},
            $args->{pesquisa}{"campo_operador_${counter}"},
            $valor_pesquisado,
            $xpprefix
        );
	 push @where, $expr;
	   
    }
    my $where = join '', @where if @where;

    # cria um array do tipo (@principal = dn, 'listar',@principal = dn, 'visualizar') dos memberOf do usuário logado
    my $grupos = join ' or ',
      map { '@principal = "' . $_ . '"' } @{ $self->user->memberof };

    # monta parte da sintaxe de checagem de grupos e permissoes, neste caso  a  ação é LISTAR
    my $check = '(' . $grupos . ') and @role="listar"';

    # monta a sintaxe de checagem de herança, para wser usado na xquery de listagem.
    my $herdar =
        '(author:autorizacao[('
      . $check
      . ')] or (@herdar/string() = "1" and (collection("volume")/vol:volume[vol:collection="'
      . $args->{id_volume}
      . '"][vol:autorizacoes/author:autorizacao['
      . $check . ']])))';

    # Query para listagem

    # contruindo o retorno para gerar o CSV - Mostrar ou não documentos invalidados. Se checkbox marcado ele mostrara tbm os inativos
    
    my $showDocInv = '';
    my $showDocInv_ = '';
    
    
    if ($args->{pesquisa}{"documentos_inativos"} ne 'on') {	
	  $showDocInv = ' and  $y/../../dc:invalidacao/text() eq \'1970-01-01T00:00:00Z\' '; 
    } else {
	  $showDocInv_ = 'if ($y/../../dc:invalidacao/text() eq "1970-01-01T00:00:00Z") then ( "" ) else ( "inativo"),';
    }
    my $return;
    # contruindo o retorno para gerar o CSV
    if ($args->{pesquisa}{gerarCSV}) {
        my $mnt_return;
        my $xpprefix = '$x/ns:doc/dc:documento/dc:documento/dc:conteudo';
        my $counter = 0;
        my @cols =  map { $args->{pesquisa}{ 'campo_col_' . $_  } }  0 .. ( $args->{pesquisa}{numero_colunas} - 1 );
        @cols = (map { $self->produce_xpath('col'. $counter++, $_).'/text()' } @cols);

        $mnt_return = ' for $y in '.$xpprefix.' return ('
                    . 'if (('.join (" or ", map { '$y/'.$_ } @cols).')'.$showDocInv.') then ('
                        . 'string-join(( '
                                . '$x/ns:nome/text(),'.$showDocInv_
                                . join (' else(" * ")," / "), ' , map { 'string-join(if($y/'.$_.') then ($y/'.$_.')' } @cols)
                    . ' else(" * ")," / ")),";-;")'

                    . ') else () )'; ;

        $return = "return (".$mnt_return." ),0)";

    } else {
       $return = 'return ($x/ns:controle/text() , '
              . $args->{xqueryret} . '),' . '('
              . $args->{interval_ini} * $args->{num_por_pagina}
              . ') + 1 ,'
              . $args->{num_por_pagina} . '' . ')';
    }
 
    my $list = $declarens
             . 'subsequence('
             . 'for $x in collection("'
             . $args->{id_volume}
             . '")/ns:dossie[ns:autorizacoes['
             . $herdar . ']] '
             . $where .$dossieFechadoAberto
             . ' let $volume := collection("volume")/vol:volume[vol:collection = "'.$args->{id_volume}.'"]/vol:autorizacoes/author:autorizacao '
             . ' let $dossie := collection("'.$args->{id_volume}.'")/ns:dossie[ns:controle = $x/ns:controle]/ns:autorizacoes/author:autorizacao  order by $x/ns:nome ascending' 
             . ' return '

             . ' let $alterar := if ($x/ns:autorizacoes/@herdar = "1") then ('
             . ' (some $verif in $volume satisfies ($verif[('.$grupos.') and @role = "alterar"])) '
             . ' or '
             . ' (some $verif in $dossie satisfies ($verif[('.$grupos.') and @role = "alterar"])) '
             . ') else ( '
             . ' some $verif in $dossie satisfies ($verif[('.$grupos.') and @role = "alterar"]) '
             . ')'

             . ' let $transferir := if ($x/ns:autorizacoes/@herdar = "1") then ('
             . ' (some $verif in $volume satisfies ($verif[('.$grupos.') and @role = "transferir"])) '
             . ' or '
             . ' (some $verif in $dossie satisfies ($verif[('.$grupos.') and @role = "transferir"])) '
             . ') else ( '
             . ' (some $verif in $dossie satisfies ($verif[('.$grupos.') and @role = "transferir"])) '
             . ')'
             . ' order by $x/ns:nome ascending '
             . $return;

    # contruindo o retorno para gerar o CSV - Tratamento e definiação das colunas do CSV
     if ($args->{pesquisa}{gerarCSV}) {
         my @csvData;
         my @label_colunas;
	 
	 if (ref($args->{pesquisa}{'labels_colunas[]'}) eq 'ARRAY') {
	      @label_colunas = @{$args->{pesquisa}{'labels_colunas[]'}} ;
	  }  else { 
	      push(@label_colunas,$args->{pesquisa}{'labels_colunas[]'}) ;
	  }
	       
	 
         my @cabecalho_colunas =   map { my $var = $_; $var =~ s/^.*-\s+//go; $var; } @label_colunas  ;
	 if ($args->{pesquisa}{"documentos_inativos"}) {	       
		unshift(@cabecalho_colunas,'Doc. inativos'); 
	 }          
	 unshift(@cabecalho_colunas,'Nome do Prontuário');  
	 
         $self->sedna->execute($list);
         while ( my $item = $self->sedna->get_item ) {
             $item =~ s/^\s//go;
              my @row = split(/;-;/,$item);   
             push (@csvData,\@row);
         }
        unshift (@csvData,\@cabecalho_colunas );
        return \@csvData;


    }

    # Contrução da query de contagem para contrução da paginação
    my $count = $declarens
              #. ' count( for $x in collection("'.$args->{id_volume}.'")/ns:dossie[ns:autorizacoes/author:autorizacao[('.$grupos.') and @role="listar"]] '
              . ' count( for $x in collection("'.$args->{id_volume}.'")/ns:dossie '
              . $where.$dossieFechadoAberto
              . ' return "" )';
	


    return {
        list     => $list,
        count    => $count,
        nsprefix => \%prefix,
        xpprefix => $xpprefix

    };
};

=item criar_dossie()

Este método realiza a persistencia das informações informadas no processo/ação de criar um novo Dossie.

=cut

txn_method 'criar_dossie' => authorized $role_criar => sub {
    my ($self, $args) = @_;


    my $autorizacoes = $args->{autorizacoes};
    my $ug       = new Data::UUID;
    my $uuid     = $ug->create();
    my $controle = $ug->to_string($uuid);

    my $acao = 'insert';
    my $role = 'role';

    my $doc = XML::LibXML::Document->new( '1.0', 'UTF-8' );

    my $res_xml = $controle_w->(
        $doc,
        {
            nome                   => uc $args->{nome},
            criacao                => DateTime->now()->set_time_zone('America/Fortaleza'),
            fechamento             => '',
            arquivamento           => '',
            estado                 => 'aberto',
            controle               => $controle,
            representaDossieFisico => $args->{dossie_fisico},
            classificacoes         => $args->{classificacoes},
            localizacao            => $args->{localizacao},
            autorizacoes           => {
                ref $autorizacoes eq 'HASH' ? %$autorizacoes : (),
                herdar => $args->{herdar_author}
            },

            doc => {},
        }
    );

    $self->sedna->conn->loadData( $res_xml->toString, $controle, $args->{id_volume} );
    $self->sedna->conn->endLoadData();    

    return $controle;

};

txn_method 'alterar_estado' => authorized $role_alterar => sub {
    my $self = shift;
    my ( $id_volume, $controle, $estado, $ip ) = @_;

    my $xq =
'declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd";';
    $xq .=
        'update replace $x in collection("'
      . $id_volume
      . '")/ns:dossie[ns:controle="'
      . $controle . '"]';
    $xq .= '/ns:estado with <ns:estado>' . $estado . '</ns:estado> ';
    $self->sedna->execute($xq);

    if ( $estado eq 'fechado' ) {
        my $xq =
'declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd";';
        $xq .=
            'update replace $x in collection("'
          . $id_volume
          . '")/ns:dossie[ns:controle="'
          . $controle . '"]';
        $xq .=
            '/ns:fechamento with <ns:fechamento>'
          . DateTime->now()->set_time_zone('America/Fortaleza')
          . '</ns:fechamento>';
        $self->sedna->execute($xq);
    }

    if ( $estado eq 'arquivado' ) {
        my $xq =
'declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd";';
        $xq .=
            'update replace $x in collection("'
          . $id_volume
          . '")/ns:dossie[ns:controle="'
          . $controle . '"]';
        $xq .=
            '/ns:arquivamento with <ns:arquivamento>'
          . DateTime->now()->set_time_zone('America/Fortaleza')
          . '</ns:arquivamento>';
        $self->sedna->execute($xq);
    }

    if ( $estado eq 'aberto' ) {
        my $xq =
'declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd";';
        $xq .=
            'update replace $x in collection("'
          . $id_volume
          . '")/ns:dossie[ns:controle="'
          . $controle . '"]';
        $xq .= '/ns:arquivamento with <ns:arquivamento></ns:arquivamento>';
        $self->sedna->execute($xq);

        $xq =
'declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd";';
        $xq .=
            'update replace $x in collection("'
          . $id_volume
          . '")/ns:dossie[ns:controle="'
          . $controle . '"]';
        $xq .= '/ns:fechamento with <ns:fechamento></ns:fechamento>';
        $self->sedna->execute($xq);
    }

};

txn_method 'auditoria_listar' => authorized $role_listar => sub {
    my $self = shift;

};

=item gerar_uuid()

=cut

txn_method 'gerar_uuid' => authorized $role_criar => sub {
    my $ug   = new Data::UUID;
    my $uuid = $ug->create();
    my $str  = $ug->to_string($uuid);
    return $str;
};

=item transferir()

Esté método realiza a persistencia da tranferência de Dossie para outro Volume.

=cut

txn_method 'transferir' => authorized $role_alterar => sub {
    my $self = shift;
    my ( $id_volume, $controle, $volume_destino, $ip ) = @_;

    my $xq_select =
'declare namespace vol = "http://schemas.fortaleza.ce.gov.br/acao/volume.xsd";
                  declare namespace dos = "http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd";
                  for $x in collection("'
      . $id_volume
      . '")/dos:dossie[dos:controle/text() eq "'
      . $controle
      . '"] return $x';

    $self->sedna->execute($xq_select);
    my $xml = $self->sedna->get_item;

    $self->sedna->conn->loadData( $xml, $controle, $volume_destino );
    $self->sedna->conn->endLoadData();

    my $xq_delete =
      'drop document "' . $controle . '" in collection "' . $id_volume . '" ';

    $self->sedna->execute($xq_delete);

};

=item pode_criar_dossie()

Esté método realiza a validação de autorização, verificando se o
user logado pode CRIAR Dossies

=cut

sub pode_criar_dossie {
    my ( $self, $id_volume ) = @_;
    return $admin_super ~~ @{$self->user->memberof} ||
        $self->_checa_autorizacao_volume( $id_volume, 'criar' )
      && $role_criar ~~ @{ $self->user->memberof };
}


=item pode_alterar_dossie()

Esté método realiza a validação de autorização, verificando se o
user logado pode ALTERAR Dossie(s)

=cut

sub pode_alterar_dossie {
    my ( $self, $id_volume, $controle ) = @_;
    return $admin_super ~~ @{$self->user->memberof} ||
         $self->_checa_autorizacao_dossie( $id_volume, 'alterar', $controle )
      && $role_alterar ~~ @{ $self->user->memberof };
}

=item pode_transferir_dossie()

Esté método realiza a validação de autorização, verificando se o
user logado pode TRANSFERIR Dossie(s)

=cut

sub pode_transferir_dossie {
    my ( $self, $id_volume, $controle ) = @_;

    return $admin_super ~~ @{$self->user->memberof} ||
         $self->_checa_autorizacao_dossie( $id_volume, 'transferir',
        $controle )
      && $role_transferir ~~ @{ $self->user->memberof };
}

=item pode_listar_dossie()

Esté método realiza a validação de autorização, verificando se o
user logado pode LISTAR Dossies

=cut

sub pode_listar_dossie {
    my ( $self, $id_volume ) = @_;
    return $admin_super ~~ @{$self->user->memberof} ||
        $self->_checa_autorizacao_dossie( $id_volume, 'listar' )
      && $role_listar ~~ @{ $self->user->memberof };
}

=item pode_ver_dossie()

Esté método realiza a validação de autorização, verificando se o
user logado pode LISTAR Dossies

=cut

sub pode_ver_dossie {
    my ( $self, $id_volume, $controle ) = @_;
    return $admin_super ~~ @{$self->user->memberof} ||
    $self->_checa_autorizacao_dossie( $id_volume, 'visualizar',
        $controle )
      && $role_ver ~~ @{ $self->user->memberof };
}


=item getDadosDossie()

Este método retona os Dados de um Dossie.

=cut

txn_method 'getDadosDossie' => authorized $role_listar => sub {
    my $self = shift;
    my ( $id_volume, $controle, $assuntos_dn, $local_dn ) = @_;

    my $xq = q|declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd";
               declare namespace dc="http://schemas.fortaleza.ce.gov.br/acao/documento.xsd";
               declare namespace cl="http://schemas.fortaleza.ce.gov.br/acao/classificacao.xsd";
               for $x in collection("|.$id_volume.q|")/ns:dossie
               where $x/ns:controle="|.$controle.q|"
               return (concat($x/ns:nome/text(),""), string-join(for $c in $x/ns:classificacoes/cl:classificacao/text()
                 return (if (ends-with($c,",|.$assuntos_dn.q|")) then (string-join(reverse(for $i in tokenize(substring-before($c,",|.$assuntos_dn.q|"),',')
                                 return (tokenize($i,'='))[2]),' - ')
                               ) else ($c)),', '),
                        string-join(
                        for $d in $x/ns:localizacao/text()
                            return (if (ends-with($d,",|.$local_dn.q|")) then (string-join(reverse(for $j in tokenize(substring-before($d,",|.$local_dn.q|"),',')
                                 return (tokenize($j,'='))[2]),' - ')
                               ) else ($d)),', '),
                        concat($x/ns:estado/text(),""), concat($x/ns:criacao/text(),""), concat($x/ns:representaDossieFisico/text(),""))|;
    $self->sedna->execute($xq);

    my $dos = {};
    while ( my $nome = $self->sedna->get_item ) {
        $dos = {
            nome           => $nome,
            classificacoes => $self->sedna->get_item,
            localizacao    => $self->sedna->get_item,
            estado         => $self->sedna->get_item,
            criacao        => $self->sedna->get_item,
            dossie_fisico  => $self->sedna->get_item > 0 ? 'Sim' : 'Não',
        };
    }

    return $dos;
};

=item autorizacoes_do_dossie()

Este método retona um XML das Autorizações do Dossie

=cut

sub autorizacoes_do_dossie {
    my ( $self, $id_volume, $controle ) = @_;

    $self->sedna->begin;

    my $query =
'declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd";
                 declare namespace dc="http://schemas.fortaleza.ce.gov.br/acao/documento.xsd";
                 declare namespace cl="http://schemas.fortaleza.ce.gov.br/acao/classificacao.xsd";
                 for $x in collection("'
      . $id_volume
      . '")/ns:dossie[ns:controle="'
      . $controle . '"]
                 return $x/ns:autorizacoes';

    $self->sedna->execute($query);
    my $xml = $self->sedna->get_item();
    $self->sedna->commit;
    return $xml;

}

=item classificacoes_do_dossie()

Este método retona um XML das Classificações do Dossie

=cut

sub classificacoes_do_dossie {
    my ( $self, $id_volume, $controle ) = @_;

    $self->sedna->begin;

    my $query =
'declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd";
                 declare namespace dc="http://schemas.fortaleza.ce.gov.br/acao/documento.xsd";
                 declare namespace cl="http://schemas.fortaleza.ce.gov.br/acao/classificacao.xsd";
                 for $x in collection("'
      . $id_volume
      . '")/ns:dossie[ns:controle="'
      . $controle . '"]
                 return $x/ns:classificacoes';

    $self->sedna->execute($query);
    my $xml = $self->sedna->get_item();
    $self->sedna->commit;
    return $xml;

}

sub localizacao_do_dossie {
    my ( $self, $id_volume, $controle ) = @_;

    $self->sedna->begin;

    my $query =
'declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd";
                 declare namespace dc="http://schemas.fortaleza.ce.gov.br/acao/documento.xsd";
                 declare namespace cl="http://schemas.fortaleza.ce.gov.br/acao/classificacao.xsd";
                 for $x in collection("'
      . $id_volume
      . '")/ns:dossie[ns:controle="'
      . $controle . '"]
                 return $x//ns:localizacao/text()';

    $self->sedna->execute($query);
    my $return = $self->sedna->get_item();
    $self->sedna->commit;


    return $return;

}

=item store_altera_dossie()

Este método realiza a persistencia das alterações realizadas no Dossie.

=cut

sub store_altera_dossie {
    my ( $self, $args ) = @_;

    # Gambis provisória -  Fazendo Update de cada campo separadamente!


    my $query_autorizacao =
' declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd"; '
      . ' declare namespace cl="http://schemas.fortaleza.ce.gov.br/acao/autorizacoes.xsd"; '
      . ' update replace $x in collection("'
      . $args->{id_volume}
      . '")/ns:dossie[ns:controle="'
      . $args->{controle}
      . '"]/ns:autorizacoes '
      . ' with '
      . $args->{autorizacoes};

    $self->sedna->begin;
    $self->sedna->execute($query_autorizacao);

    my $query_nome =
' declare namespace ds="http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd"; '
      . ' update replace $x in collection("'
      . $args->{id_volume}
      . '")/ds:dossie[ds:controle="'
      . $args->{controle}
      . '"]/ds:nome '
      . ' with <nome xmlns="http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd">'
      . $args->{nome}
      . '</nome> ';

    $self->sedna->execute($query_nome);

    my $query_classificacoes =
' declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd"; '
      . ' declare namespace cl="http://schemas.fortaleza.ce.gov.br/acao/classificacao.xsd"; '
      . ' update replace $x in collection("'
      . $args->{id_volume}
      . '")/ns:dossie[ns:controle="'
      . $args->{controle}
      . '"]/ns:classificacoes '
      . ' with '
      . $args->{classificacoes};

    $self->sedna->execute($query_classificacoes);

    my $query_dossie_fisico =
' declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd"; '
      . ' declare namespace cl="http://schemas.fortaleza.ce.gov.br/acao/classificacao.xsd"; '
      . ' update replace $x in collection("'
      . $args->{id_volume}
      . '")/ns:dossie[ns:controle="'
      . $args->{controle}
      . '"]/ns:representaDossieFisico '
      . ' with <representaDossieFisico xmlns="http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd">'
      . $args->{dossie_fisico}
      . '</representaDossieFisico>';

    #$self->sedna->execute($query_dossie_fisico);

    my $query_localizacao =
' declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd"; '
      . ' declare namespace cl="http://schemas.fortaleza.ce.gov.br/acao/classificacao.xsd"; '
      . ' update replace $x in collection("'
      . $args->{id_volume}
      . '")/ns:dossie[ns:controle="'
      . $args->{controle}
      . '"]/ns:localizacao '
      . ' with <localizacao xmlns="http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd">'
      . $args->{localizacao}
      . '</localizacao> ';

    $self->sedna->execute($query_localizacao);

    $self->sedna->commit;

    $self->update_autorizacoes_dos($args->{id_volume}, $args->{controle}, $self->desserialize_autorizacoes($args->{autorizacoes})) if $args->{qtdDocumentos} > 0;
}


sub boxDossieStatistics {
    my ( $self, $id_volume ) = @_;
    
    my $declarens = 'declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd";'
                  .'declare namespace dc="http://schemas.fortaleza.ce.gov.br/acao/documento.xsd";'
                  .'declare namespace vol="http://schemas.fortaleza.ce.gov.br/acao/volume.xsd";'
                  .'declare namespace cl="http://schemas.fortaleza.ce.gov.br/acao/classificacao.xsd";'
                  .'declare namespace author="http://schemas.fortaleza.ce.gov.br/acao/autorizacoes.xsd";';
    my $where = '';
   
    my $count = $declarens
              . ' count( for $x in collection("'.$id_volume.'")/ns:dossie '
              . $where
              . ' return "" )';
   $self->sedna->begin;
   $self->sedna->execute($count); 
   my $total = $self->sedna->get_item();
   $self->sedna->commit;
        
    # Contagem de prontuários FECHADOS para construção de Caixa com informações estatísticas e filtros por prontuários fechados/abertos
   my $count_abertos = $declarens
              . ' count( for $x in collection("'.$id_volume.'")/ns:dossie '
              . $where . 'where $x/ns:estado/text() eq \'aberto\'  '
              . ' return "" )';

  $self->sedna->begin;
  $self->sedna->execute($count_abertos);  
  my $abertos = $self->sedna->get_item();          
  $self->sedna->commit;

  return { total   => $total,
          abertos => $abertos,
          fechados  => $total - $abertos
          };
}

=item getCountDocsInDossie()

Retorna o número de documentos dentro de um dossie/prontuário
Parametros id_volume, $controle

=cut

sub getCountDocsInDossie {
    my ( $self, $id_volume ,$controle  ) = @_;
    

    
    $self->sedna->begin;

    my $query =
				'declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd";
                 declare namespace dc="http://schemas.fortaleza.ce.gov.br/acao/documento.xsd";
                 declare namespace cl="http://schemas.fortaleza.ce.gov.br/acao/classificacao.xsd";
                 count(for $x in collection("'
      . $id_volume
      . '")/ns:dossie[ns:controle="'
      . $controle . '"]/ns:doc/dc:documento
                 return $x)';

    $self->sedna->execute($query);
    my $total = $self->sedna->get_item();     
    $self->sedna->commit;
    return $total;
    
}
=head1 COPYRIGHT AND LICENSING

Copyright 2010 - Prefeitura de Fortaleza. Este software é licenciado
sob a GPL versão 2.

=cut

1;
