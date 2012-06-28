package Acao::Controller::Auth::Registros::Volume::Dossie;

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
use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller'; }
use Data::Dumper;
use List::MoreUtils 'pairwise';

#with 'Acao::Role::Controller::Autorizacao'   => { modelcomponent => 'Dossie' };
#with 'Acao::Role::Controller::Classificacao' => { modelcomponent => 'Dossie' };
with 'Acao::Role::Auditoria'                 => { category       => 'Dossie' };

=head1 NAME

Acao::Controller::Auth::Registros::Volume::Dossie - Controlador
que implementa as ações de digitação de uma leitura específica.

=head1 ACTIONS

=over

=item base

Carrega para o stash os dados do dossiê.

=cut

sub base : Chained('/auth/registros/volume/get_volume') : PathPart('dossie') :
  CaptureArgs(0) {
    my ( $self, $c, ) = @_;
}

sub get_dossie : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $controle ) = @_;
    Log::Log4perl::MDC->put( 'Dossie', $controle );
    $c->stash->{controle} = $controle;
    #   Checa se user logado tem autorização para ver o Dossie
    if ( !$c->model('Dossie')->pode_ver_dossie( $c->stash->{id_volume},$c->stash->{controle} ) ) {
        $c->flash->{autorizacao} = 'dossie-visualizar';
        $c->res->redirect( $c->uri_for_action('/auth/registros/volume/dossie/lista'),[$c->stash->{id_volume},$c->stash->{controle}] );
        return;
    }

}

=item form

Delega à view a renderização do formulário desse dossiê.

=cut

sub lista : Chained('base') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    #   Checa se user logado tem autorização para listar os Dossies (Ver em Volume)
    if ( !$c->model('Volume')->pode_ver_volume( $c->stash->{id_volume} ) ) {
        $c->flash->{autorizacao} = 'volume-visualizar';
        $c->res->redirect( $c->uri_for_action('/auth/registros/volume/lista') );
        return;
    }
    if ($c->req->params->{dossiesAbertos} || $c->req->params->{dossiesFechados}) {
        $c->stash->{'dossiesAbertos'} =  $c->req->params->{dossiesAbertos} eq 'on' ? 'checked="checked"' : '';
        $c->stash->{'dossiesFechados'} = $c->req->params->{dossiesFechados} eq 'on' ? 'checked="checked"' : '';
   } else {
        $c->stash->{'dossiesFechados'} = 'checked="checked"';
        $c->stash->{'dossiesAbertos'}  = 'checked="checked"';
   
   }
    
    if ($c->req->param('gerarCSV')) {
        my $datacsv = $c->model('Dossie')->listar_dossies({ pesquisa => \%{$c->req->params}, id_volume => $c->stash->{id_volume}});
        $c->stash->{'csv'} = {'data' => $datacsv };
        $c->stash->{'download'} = 'text/csv';
        #
        $c->forward('Acao::View::Download');

     }


}

sub form : Chained('base') : PathPart('criardossie') : Args(0) {
    my ( $self, $c ) = @_;
        #   Checa se user logado tem autorização para criar dossies em Volume
    if ( !$c->model('Dossie')->pode_criar_dossie( $c->stash->{id_volume} ) ) {
        $c->flash->{autorizacao} = 'volume-criar';
        $c->res->redirect( $c->uri_for_action('/auth/registros/volume/lista') );
        return;
    }

    $c->stash->{autorizacoes} = $c->model("Dossie")->new_autorizacao();
    my $xml_class_vol = $c->model('Volume')->classificacoes_do_volume($c->stash->{id_volume});
    my $hash_class_vol = $c->model('Volume')->desserialize_classificacoes($xml_class_vol);
    $c->stash->{classificacoes} = $c->model("Dossie")->new_classificacao($hash_class_vol);
    $c->stash->{basedn}       = $c->model("LDAP")->grupos_dn;
    $c->stash->{class_basedn} = $c->model("LDAP")->assuntos_dn;
    $c->stash->{herdar} or $c->stash->{herdar} = 1;
    $c->stash->{local_basedn}   =   $c->model("Volume")->getDadosVolumeId($c->stash->{id_volume})->{localizacao};





}

sub transferir_lista : Chained('get_dossie') : PathPart('transferir_lista') :
  Args(0) {
    my ( $self, $c ) = @_;


  #   Checa se user logado tem autorização para executar a ação 'Transferir'
     if (!$c->model('Dossie')->pode_transferir_dossie($c->stash->{id_volume},$c->stash->{controle} )) {
     $c->flash->{autorizacao} = 'dossie-transferir';
     $c->res->redirect( $c->uri_for_action('/auth/registros/volume/dossie/lista',[$c->stash->{id_volume}] ));
     return
    }

    if (
        !$c->model('Dossie')->pode_transferir_dossie(
            $c->stash->{id_volume},
            $c->stash->{controle}
        )
      )
    {
        $c->flash->{autorizacao} =
          'Ops! Você não tem autorização para isso, consulte...';
        $c->res->redirect(
            $c->uri_for_action(
                '/auth/registros/volume/dossie/lista',
                [ $c->stash->{id_volume} ]
            )
        );
    }

}

sub store : Chained('base') : PathPart('store') : Args(0) {
    my ( $self, $c ) = @_;

    #   Checa se user logado tem autorização para criar dossies em Volume
    if ( !$c->model('Dossie')->pode_criar_dossie( $c->stash->{id_volume} ) ) {
        $c->flash->{autorizacao} = 'volume-criar';
        $c->res->redirect( $c->uri_for_action('/auth/registros/volume/lista') );
        return;
    }
    $c->stash->{basedn} = $c->req->param('basedn')
      || $c->model("LDAP")->grupos_dn;
    $c->stash->{class_basedn} = $c->req->param('class_basedn')
      || $c->model("LDAP")->assuntos_dn;
    $c->stash->{nome}           = $c->req->param('nome');
    $c->stash->{template}       = 'auth/registros/volume/dossie/form.tt';
    $c->stash->{classificacoes} = $c->req->param('classificacoes');
    $c->stash->{autorizacoes}   = $c->req->param('autorizacoes');
    $c->stash->{localizacao}    = $c->req->param('localizacao') || $c->model('Volume')->getDadosVolumeId($c->stash->{id_volume})->{localizacao} ;

    my $representaDossieFisico;
    my $herdar_author;

    if ( $c->req->param('representaDossieFisico') eq 'on' ) {
        $representaDossieFisico = '1';
    }
    else {
        $representaDossieFisico = '0';
    }

    if ( $c->req->param('herdar_author') eq 'on' ) {
        $herdar_author = '1';
    }
    else {
        $herdar_author = '0';
    }

    if ( $c->req->param('local_virtual') eq 'on' ) {
        $c->stash->{localizacao}  = $c->model('LDAP')->local_dn;
    }

    $c->stash->{herdar} = $herdar_author;

    my $id;

    eval {
            $id = $c->model('Dossie')->criar_dossie({
            ip              => $c->req->address,
            nome            => $c->req->param('nome'),
            id_volume       => $c->req->param('id_volume'),
            dossie_fisico   => $representaDossieFisico,
            classificacoes  => $c->model('Dossie')->desserialize_classificacoes( $c->stash->{classificacoes} ),
            localizacao     => $c->stash->{localizacao} ,
            herdar_author   => $herdar_author,
            autorizacoes    => $c->model('Dossie')->desserialize_autorizacoes( $c->stash->{autorizacoes} ),            
        }
        );

        $self->audit_criar( $id, $c->req->param('nome') );
    };

    if   ($@) { $c->flash->{erro}    = $@ . ""; }
    else      { $c->flash->{sucesso} = 'Dossie criado com sucesso'; }
    $c->res->redirect(
        $c->uri_for_action(
            '/auth/registros/volume/dossie/documento/lista',
            [ $c->req->param('id_volume'), $id ]
        )
    );
}

sub alterar_estado : Chained('get_dossie') : PathPart('alterar_estado') :
  Args(1) {
    my ( $self, $c, $estado ) = @_;
    #   Checa se user logado tem autorização para executar a ação 'Alterar'
    if (!$c->model('Dossie')->pode_alterar_dossie($c->stash->{id_volume},$c->stash->{controle} )) {
     $c->flash->{autorizacao} = 'dossie-alterar';
     $c->res->redirect( $c->uri_for_action('/auth/registros/volume/dossie/lista',[$c->stash->{id_volume}] ));
     return
    }

    eval {
        $c->model('Dossie')->alterar_estado(
            $c->stash->{id_volume},
            $c->stash->{controle},
            $estado, $c->req->address
        );
    };
    if ($@) {
        $c->flash->{erro} = $@;
    }
    else {
        $c->flash->{sucesso} = 'Estado alterado com sucesso!';
    }
    $self->audit_alterar( 'estado: ', $estado );
    $c->res->redirect(
        $c->uri_for_action(
            '/auth/registros/volume/dossie/lista',
            [ $c->stash->{id_volume} ]
        )
    );
}

sub transferir : Chained('get_dossie') : PathPart('transferir') : Args(0) {
    my ( $self, $c ) = @_;
    my $controle = $c->stash->{controle};

  #   Checa se user logado tem autorização para executar a ação 'Transferir'
 if (!$c->model('Dossie')->pode_transferir_dossie($c->stash->{id_volume},$c->stash->{controle} )) {
     $c->flash->{autorizacao} = 'dossie-transferir';
     $c->res->redirect( $c->uri_for_action('/auth/registros/volume/dossie/lista',[$c->stash->{id_volume}] ));
     return;
 }

    if (
        !(
            $c->model('Dossie')
            ->pode_transferir_dossie( $c->stash->{id_volume}, $controle )
            && $c->model('Dossie')
            ->pode_criar_dossie( $c->req->param('volume_destino') )
        )
      )
    {
        $c->flash->{autorizacao} =
          'Ops! Você não tem autorização para isso, consulte...';
        $c->res->redirect(
            $c->uri_for_action(
                '/auth/registros/volume/dossie/lista',
                [ $c->stash->{id_volume} ]
            )
        );
    }

    eval {
        $c->model('Dossie')->transferir(
            $c->stash->{id_volume},
            $controle, $c->req->param('volume_destino'),
            $c->req->address
        );
    };
    if ($@) {
        $c->flash->{erro} = $@;
    }
    else {
        $c->flash->{sucesso} = 'Alterado com sucesso!';
    }

    $self->audit_alterar( 'transferir: ', $controle );
    $c->res->redirect(
        $c->uri_for_action(
            '/auth/registros/volume/dossie/lista',
            [ $c->stash->{id_volume} ]
        )
    );
}

sub alterar_dossie : Chained('get_dossie') : PathPart('alterar') : Args(0) {
    my ( $self, $c ) = @_;

#   Checa se user logado tem autorização para executar a ação 'Alterar'
 if (!$c->model('Dossie')->pode_alterar_dossie($c->stash->{id_volume},$c->stash->{controle} )) {
     $c->flash->{autorizacao} = 'dossie-alterar';
     $c->res->redirect( $c->uri_for_action('/auth/registros/volume/dossie/lista',[$c->stash->{id_volume}] ));
     return;
 }

    my $initial_principals = $c->model('LDAP')->memberof_grupos_dn();

    my $herdar = $c->model('Dossie')->desserialize_autorizacoes(
        $c->model('Dossie')->autorizacoes_do_dossie(
            $c->stash->{id_volume},
            $c->stash->{controle}
        )
    );

    $c->stash->{herdar} = $herdar->{herdar};
    $c->stash->{autorizacoes} =
      $c->model('Dossie')
      ->autorizacoes_do_dossie( $c->stash->{id_volume}, $c->stash->{controle} );
    $c->stash->{classificacoes} =
      $c->model('Dossie')->classificacoes_do_dossie( $c->stash->{id_volume},
        $c->stash->{controle} );
    $c->stash->{local_basedn}  = $c->model("Dossie")->localizacao_do_dossie($c->stash->{id_volume},$c->stash->{controle}) ne '1' ?
            $c->model("Dossie")->localizacao_do_dossie($c->stash->{id_volume},$c->stash->{controle}) :
            $c->model("Volume")->getDadosVolumeId($c->stash->{id_volume})->{localizacao} ;

	$c->stash->{qtdDocumentos} = $c->model("Dossie")->getCountDocsInDossie($c->stash->{id_volume}, $c->stash->{controle});
    $c->stash->{class_basedn} = $c->req->param('class_basedn')
      || $c->model("LDAP")->assuntos_dn;
    $c->stash->{template} = 'auth/registros/volume/dossie/form_alterar.tt';

}

sub store_alterar : Chained('get_dossie') : PathPart('store_alterar') : Args(0)
{
    my ( $self, $c ) = @_;

#   Checa se user logado tem autorização para executar a ação 'Alterar'
    if (!$c->model('Dossie')->pode_alterar_dossie($c->stash->{id_volume},$c->stash->{controle} )) {
     $c->flash->{autorizacao} = 'dossie-alterar';
     $c->res->redirect( $c->uri_for_action('/auth/registros/volume/lista' ));
     return;
    }
    my $representaDossieFisico;
    my $herdar_author;

    $c->stash->{basedn} = $c->req->param('basedn')
      || $c->model("LDAP")->grupos_dn;
    $c->stash->{class_basedn} = $c->req->param('class_basedn')
      || $c->model("LDAP")->assuntos_dn;
    $c->stash->{template} = 'auth/registros/volume/dossie/form_alterar.tt';
    $c->stash->{classificacoes} = $c->req->param('classificacoes');
    $c->stash->{autorizacoes}   = $c->req->param('autorizacoes');
    $c->stash->{localizacao}    = $c->req->param('localizacao') || $c->model('Volume')->getDadosVolumeId($c->stash->{id_volume})->{localizacao} ;

    if ( $c->req->param('representaDossieFisico') eq 'on' ) {
        $representaDossieFisico = '1';
    }
    else {
        $representaDossieFisico = '0';
    }

    if ( $c->req->param('herdar_author') eq 'on' ) {
        $herdar_author = '1';
    }
    else {
        $herdar_author = '0';
    }

    if ( $c->req->param('local_virtual') eq 'on' ) {
        $c->stash->{localizacao}  = $c->model('LDAP')->local_dn;
    }

    $c->stash->{herdar} = $herdar_author;

    my $autorizacoes_h =
      $c->model('Dossie')
      ->desserialize_autorizacoes( $c->req->param('autorizacoes') );
    $autorizacoes_h->{'herdar'} = $herdar_author;

    eval {
        $c->model('Dossie')->store_altera_dossie(
            {
                id_volume => $c->stash->{id_volume},
                controle  => $c->stash->{controle},
                autorizacoes =>
                  $c->model('Dossie')->serialize_autorizacoes($autorizacoes_h),
                nome           => $c->req->param('nome'),
                classificacoes => $c->req->param('classificacoes'),
                localizacao    => $c->stash->{localizacao} ,
                dossie_fisico  => $representaDossieFisico,
                ip             => $c->req->address,
                qtdDocumentos  => $c->req->param('qtdDocumentos')
            }
        );
        $self->audit_alterar('geral');

    };

    if   ($@) { $c->flash->{erro}    = $@ . ""; }
    else      { $c->flash->{sucesso} = 'Alteraçoes realizada com sucesso'; }
    $c->res->redirect(
        $c->uri_for_action(
            '/auth/registros/volume/dossie/documento/lista',
            [ $c->stash->{id_volume}, $c->stash->{controle} ]
        )
    );
}

=head1 COPYRIGHT AND LICENSING

Copyright 2010 - Prefeitura de Fortaleza. Este software é licenciado
sob a GPL versão 2.

=cut

1;
