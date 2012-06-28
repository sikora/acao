use Sedna;
use Text::Template;
use warnings;
use lib '/home/pauloneto/devel/acao/Acao/lib';
use Acao;
use Data::Dumper;
use strict;
use utf8;
use Encode;
use Storable;
use DBI;
use warnings;
$| = 1;
my $hash;
my $template = Text::Template->new(TYPE => 'FILE',  SOURCE => 'parada.xml');
#if (! -f 'habitafor.hsh') {
    my $dbh = DBI->connect("DBI:Pg:dbname=acao;host=127.0.0.1", "acao", "12345");
    open(FILE, "<:encoding(UTF-8)", "consulta.sql");
    my $sql;
    while (<FILE>){$sql .= $_;}
    close FILE;
    $sql =~ s/\n/ /g;

    $hash = $dbh->selectall_hashref($sql, 'IdCadastro');
#    store $hash, './habitafor.hsh';
#}
#else{
#    $hash = retrieve('./habitafor.hsh');
#}

my $i=1;
my $xml;
print "processando...\n";
foreach my $k (keys %{$hash}) {
    $xml = $template->fill_in(HASH => $hash->{$k});
    $xml = decode( 'utf8', $xml );
    my $controle = criaProntuario($hash->{$k}{chefe});
    inserirDocumento( $xml, $controle);
#    warn  $xml;
    print "$hash->{$k}{NrFormulario} inserindo no total de $i forms";
    print "\b" x length("$hash->{$k}{NrFormulario} inserindo no total de $i forms");
    $i++;
}

my $auth = {
          'autorizacao' => [
                           {
                             'principal' => 'ou=SIS,o=CTI,o=GP,o=PMF,dc=adm,dc=diretorio,dc=fortaleza,dc=ce,dc=gov,dc=br',
                             'role' => 'alterar'
                           },
                           {
                             'principal' => 'ou=SIS,o=CTI,o=GP,o=PMF,dc=adm,dc=diretorio,dc=fortaleza,dc=ce,dc=gov,dc=br',
                             'role' => 'criar'
                           },
                           {
                             'principal' => 'ou=SIS,o=CTI,o=GP,o=PMF,dc=adm,dc=diretorio,dc=fortaleza,dc=ce,dc=gov,dc=br',
                             'role' => 'listar'
                           },
                           {
                             'principal' => 'ou=SIS,o=CTI,o=GP,o=PMF,dc=adm,dc=diretorio,dc=fortaleza,dc=ce,dc=gov,dc=br',
                             'role' => 'visualizar'
                           },
                           {
                             'principal' => 'ou=SIS,o=CTI,o=GP,o=PMF,dc=adm,dc=diretorio,dc=fortaleza,dc=ce,dc=gov,dc=br',
                             'role' => 'transferir'
                           }
                         ]
        };

{   package DumbUser;
    use Moose;
    sub memberof {[ Acao->config->{roles}{dossie}{criar}, Acao->config->{roles}{volume}{criar} , Acao->config->{roles}{documento}{criar}]}
    sub uid {'importacao.habitafor'}
    sub id {'importacao.habitafor'}
    sub cn {'Importação.habitafor'}
}

# chamada do método criaProntuario passando os respectivos paramentros 
sub criaProntuario{
        my($nome, $representaVolumeFisico, $classificacoes,$autorizacoes) = (shift , 0, 
                                                                {'classificacao' => ["cn=Habitação,dc=assuntos,dc=diretorio,dc=fortaleza,dc=ce,dc=gov,dc=br"]}, 
                                                                $auth );
        my $ip = '127.0.0.1';
		my $localizacao = 'dc=local,dc=diretorio,dc=fortaleza,dc=ce,dc=gov,dc=br';	
        my $id_volume = 'volume-B6273E00-BEC4-11E1-9AF0-A4123BA7D1BA';
        my $herdar_author = '1';
        my $dossie_fisico = 0;
		$nome =~ tr/a-zàáâãäåæçèéêëìíîïðñòóôõöøùúûüý/A-ZÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝ/;
        my $octets_nome = decode( 'utf8', $nome );
        my $model = Acao::Model::Dossie->new(user => DumbUser->new(), sedna => Acao->model('Sedna'), dbic => Acao->model('DB')->schema);
        my $collection = $model->criar_dossie( {ip=>$ip, nome=>$octets_nome, id_volume =>$id_volume, dossie_fisico=>$dossie_fisico, 
                                                                            classificacoes=>$classificacoes, localizacao=>$localizacao, 
                                                                            herdar_author=>$herdar_author, autorizacoes=>$autorizacoes});
      #  warn "collection $collection criada com sucesso!";
        return $collection;
    }
# chamada do método inserirDocumento passando os respectivos paramentros e inserindo dados de acordo com o padrao do documento 
sub inserirDocumento{
	    my($xml, $controle) = @_;
        my ($representaVolumeFisico, $classificacoes) = ( 0, {'classificacao' => ["cn=Habitação,dc=assuntos,dc=diretorio,dc=fortaleza,dc=ce,dc=gov,dc=br"]} );
        my $autorizacoes = $auth;
        my $ip = '127.0.0.1';
        my $id_volume = 'volume-B6273E00-BEC4-11E1-9AF0-A4123BA7D1BA';
        my $xsdDocumento ='http://schemas.fortaleza.ce.gov.br/acao/habitafor-boletiminformacaocadastral-bic.xsd';
        my $representaDocumentoFisico = 0;
        my $herdar_author = '1';
		my $localizacao = 'dc=local,dc=diretorio,dc=fortaleza,dc=ce,dc=gov,dc=br';	
        my $id_Prontuario ='$collection';
        my $id_documento ='';       
        my $dossie_fisico = 0;
        my $model = Acao::Model::Documento->new(user => DumbUser->new(), sedna => Acao->model('Sedna'), dbic => Acao->model('DB')->schema);
        my $cDoc = 
          $model->inserir_documento( $ip, $xml, $id_volume, $controle, $xsdDocumento, $representaDocumentoFisico, $herdar_author, $autorizacoes, $id_documento);
     #   warn " Documento $cDoc inserido com sucesso!";                                                     
 }

