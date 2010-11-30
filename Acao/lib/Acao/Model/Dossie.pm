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
use Encode;
use Data::UUID;
use Data::Dumper;

use constant DOSSIE_NS =>'http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd';
my $controle = XML::Compile::Schema->new( Acao->path_to('schemas/dossie.xsd') );
$controle->importDefinitions( Acao->path_to('schemas/documento.xsd') );
$controle->importDefinitions( Acao->path_to('schemas/auditoria.xsd') );
my $controle_w = $controle->compile( WRITER => pack_type( DOSSIE_NS, 'dossie' ), use_default_namespace => 1 );

my $role_alterar = Acao->config->{'roles'}->{'dossie'}->{'alterar'};
my $role_criar = Acao->config->{'roles'}->{'dossie'}->{'criar'};
my $role_listar = Acao->config->{'roles'}->{'dossie'}->{'listar'};

use constant AUDITORIA_NS =>'http://schemas.fortaleza.ce.gov.br/acao/auditoria.xsd';
my $controle_audit = XML::Compile::Schema->new( Acao->path_to('schemas/auditoria.xsd') );
my $controle_audit_w = $controle_audit->compile( WRITER => pack_type( AUDITORIA_NS, 'auditoria' ), use_default_namespace => 1 );


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
    return $self->sedna->get_document( $dossie );
};



=item listar_dossies()

Retorna os dossies os quais o usuário autenticado tem acesso.

=cut

txn_method 'listar_dossies' => authorized $role_listar => sub {
    my ($self, $args) = @_;

    my $for = 'collection("'.$args->{id_volume}.'")/ns:dossie';

    my $declare_namespace  = 'declare namespace ns = "http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd";';
       $declare_namespace .= 'declare namespace dc = "http://schemas.fortaleza.ce.gov.br/acao/documento.xsd";';
       $declare_namespace .= 'declare namespace pes = "http://schemas.fortaleza.ce.gov.br/acao/sdh-identificacaoPessoal.xsd";';

    my $xquery_for = 'for $x in '.$for;

    my $xquery_where  = ' where '.$args->{where_nome_membro};
       $xquery_where .= ' and '.$args->{where_nome_mae};

    my $list  = $declare_namespace.' subsequence('.$xquery_for.$xquery_where;
       $list .=                    ' order by $x/ns:criacao descending';
       $list .=                    ' return ($x/ns:controle/text() , '.$args->{xqueryret}.'), ';
       $list .=                    '(('.$args->{interval_ini}.' * '.$args->{num_por_pagina}.') + 1), '.$args->{num_por_pagina}.')';


    my $count = $declare_namespace.'count('.$xquery_for.$xquery_where.' return "")';


    $self->auditoria({ ip => $args->{ip}, operacao => 'list', for => $for, dados => $for   });

    return
        {
          list       => $list,
          count      => $count
        };
};

sub auditoria  {
    my ($self, $args) = @_;
    my $doc = XML::LibXML::Document->new( '1.0', 'UTF-8' );
    my $audit = $controle_audit_w->($doc,
                                    {
                                      data => DateTime->now(),
                                      usuario => $self->user->id,
                                      acao => $args->{operacao},
                                      ip => $args->{ip},
                                      dados => $args->{dados} || '',
                                    },
                               );
    my $xq_audit = 'declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd";
                update insert ('.$audit->toString.') into '.$args->{for}.'/ns:audit';
    $self->sedna->execute($xq_audit);
}

=item criar_dossie()

=cut

txn_method 'criar_dossie' => authorized $role_criar => sub {
    my $self = shift;
    my ($ip, $nome, $id_volume, $controle, $representaDossieFisico, $classificacao, $localizacao) = @_;

    my $acao = 'insert';
    my $role = 'role';

    my $doc = XML::LibXML::Document->new( '1.0', 'UTF-8' );

    my $res_xml = $controle_w->($doc,
                                {
                                    nome         => $nome,
                                    criacao      => DateTime->now(),
                                    fechamento   => '',
                                    arquivamento => '',
                                    estado       => 'aberto',
                                    controle     => $controle,
                                    representaDossieFisico => $representaDossieFisico,
                                    classificacao => $classificacao,
                                    localizacao => $localizacao,
                                    autorizacao => {
                                                    principal => $self->user->id,
                                                    role => $role,
                                                    dataIni => DateTime->now(),
                                                    dataFim => '',
                                                   },
                                    audit      =>  {},
                                    doc=>{},
                                }
                               );
    $self->sedna->conn->loadData( $res_xml->toString, $controle, $id_volume );
    $self->sedna->conn->endLoadData();

    my $doc_audit = XML::LibXML::Document->new( '1.0', 'UTF-8' );
    my $audit = $controle_audit_w->($doc_audit,
                                            {
                                              data => DateTime->now(),
                                              usuario => $self->user->id,
                                              acao => 'insert',
                                              ip => $ip,
                                              dados => '$self->sedna->conn->loadData('.$res_xml->toString.','.$controle.','. $id_volume.');',
                                            },
                                   );

   my $xq_audit = 'declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd";
                    update insert ('.$audit->toString.') into collection("'.$id_volume.'")/ns:dossie[ns:controle="'.$controle.'"]/ns:audit';
    $self->sedna->execute($xq_audit);

};

txn_method 'alterar_estado' => authorized $role_alterar => sub {
    my $self = shift;
    my ( $id_volume, $controle, $estado, $ip ) = @_;

    my $xq  = 'declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd";';
       $xq .= 'update replace $x in collection("'.$id_volume.'")/ns:dossie[ns:controle="'.$controle.'"]';
       $xq .= '/ns:estado with <ns:estado>'.$estado.'</ns:estado> ';
    $self->sedna->execute($xq);

    if($estado eq 'fechado')
    {
            my $xq  = 'declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd";';
               $xq .= 'update replace $x in collection("'.$id_volume.'")/ns:dossie[ns:controle="'.$controle.'"]';
               $xq .= '/ns:fechamento with <ns:fechamento>'.DateTime->now().'</ns:fechamento>';
            $self->sedna->execute($xq);
    }

    if($estado eq 'arquivado')
    {
            my $xq  = 'declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd";';
               $xq .= 'update replace $x in collection("'.$id_volume.'")/ns:dossie[ns:controle="'.$controle.'"]';
               $xq .= '/ns:arquivamento with <ns:arquivamento>'.DateTime->now().'</ns:arquivamento>';
            $self->sedna->execute($xq);
    }

    if($estado eq 'aberto')
    {
            my $xq  = 'declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd";';
               $xq .= 'update replace $x in collection("'.$id_volume.'")/ns:dossie[ns:controle="'.$controle.'"]';
               $xq .= '/ns:arquivamento with <ns:arquivamento></ns:arquivamento>';
            $self->sedna->execute($xq);

               $xq  = 'declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd";';
               $xq .= 'update replace $x in collection("'.$id_volume.'")/ns:dossie[ns:controle="'.$controle.'"]';
               $xq .= '/ns:fechamento with <ns:fechamento></ns:fechamento>';
            $self->sedna->execute($xq);
    }

    my $doc = XML::LibXML::Document->new( '1.0', 'UTF-8' );
    my $audit = $controle_audit_w->($doc,
                                        {
                                          data => DateTime->now(),
                                          usuario => $self->user->id,
                                          acao => 'replace',
                                          ip => $ip,
                                          dados => $xq,
                                        },
                                   );

    my $xq_audit = 'declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd";
                    update insert ('.$audit->toString.') into collection("'.$id_volume.'")/ns:dossie[ns:controle="'.$controle.'"]/ns:audit';

    $self->sedna->execute($xq_audit);
};

txn_method 'auditoria_listar' => authorized $role_listar => sub {
    my $self = shift;
    my ($ip, $controles, $id_volume) = @_;
    my (@control, $where);

    my $dados  = 'declare namespace ns = "http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd";';
       $dados .= 'for $x in collection("'.$id_volume.'") return $x';

    my $doc = XML::LibXML::Document->new( '1.0', 'UTF-8' );

    my $audit = $controle_audit_w->($doc,
                                        {
                                          data => DateTime->now(),
                                          usuario => $self->user->id,
                                          acao => 'list',
                                          ip => $ip,
                                          dados => $dados,
                                        },
                                   );
      @control = split(/___/,$controles);

    foreach (@control){
        $where .= ' or ns:controle = "'. $_ .'"';
    }

   my $xq_audit = 'declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd";
                    update insert ('.$audit->toString.') into collection("'.$id_volume.'")/ns:dossie[1=1 '.$where.']/ns:audit';

    $self->sedna->execute($xq_audit);
};

txn_method 'gerar_uuid' => authorized $role_criar => sub {
    my $ug  = new Data::UUID;
    my $uuid = $ug->create();
    my $str = $ug->to_string($uuid);
   return $str;
};

txn_method 'transferir' => authorized $role_alterar => sub {
    my $self = shift;
    my ( $id_volume, $controle, $volume_destino, $ip ) = @_;

    my $xq_select = 'declare namespace vol = "http://schemas.fortaleza.ce.gov.br/acao/volume.xsd";
                  declare namespace dos = "http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd";
                  for $x in collection("'.$id_volume.'")/dos:dossie[dos:controle/text() eq "'.$controle.'"] return $x';

    $self->sedna->execute($xq_select);
    my $xml = $self->sedna->get_item;

    $self->sedna->conn->loadData( $xml, $controle, $volume_destino );
    $self->sedna->conn->endLoadData();

    my $xq_delete = 'drop document "'.$controle.'" in collection "'.$id_volume.'" ';
    $self->sedna->execute($xq_delete);

    my $doc = XML::LibXML::Document->new( '1.0', 'UTF-8' );
    my $audit = $controle_audit_w->($doc,
                                        {
                                          data => DateTime->now(),
                                          usuario => $self->user->id,
                                          acao => 'Transfer',
                                          ip => $ip,
                                          dados => '$self->sedna->conn->loadData('.$xq_select.','.$controle.','. $volume_destino.');',
                                        },
                                   );

    my $xq_audit = 'declare namespace ns="http://schemas.fortaleza.ce.gov.br/acao/dossie.xsd"; 
                    update insert ('.$audit->toString.') into collection("'.$volume_destino.'")/ns:dossie[ns:controle="'.$controle.'"]/ns:audit';

    $self->sedna->execute($xq_audit);

};

=head1 COPYRIGHT AND LICENSING

Copyright 2010 - Prefeitura de Fortaleza. Este software é licenciado
sob a GPL versão 2.

=cut

42;
