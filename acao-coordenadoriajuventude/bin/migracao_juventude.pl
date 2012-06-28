use Sedna;
use warnings;
use lib '/home/sikora/devel/acao/Acao/lib';
use Acao;
use Data::Dumper;
use strict;
use utf8;
use Encode;
use Storable;
use warnings;
use Spreadsheet::Read;

my $ref = ReadData ("FICHA.xls");

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

my $x;
my $cell = cr2cell (2, 2);
my $valor = $ref->[1]{$cell};
# array onde sera atribuido os nomes e armazenado os campos contido no documento xls
my @array = ('data', 'organizacao', 'endereco', 'bairro', 'cidade', 'cep', 'fone', 'email', 'site', 'blog', 'ano_fundacao', 
             'cnpj', 'tp_org', 'temas', 'atividade', 'territ_atua', 'pub_alvo', 'fx_etaria', 'qt_jovens', 'local_atv', 
             'freq_reuniao','funcao', 'resp', 'fone_resp', 'email_resp' );
my @docs;
my $i = 2;
 # laço para atribuir valores ao array varrendo todo o documento xls
while($valor ne ''){        
	my %hash;
    $x=1;
    foreach my $a(@array){		
        $cell = cr2cell ( $x, $i);
        $valor = $ref->[1]{$cell};
        $hash{$a} = $valor;
        $x++;
		$cell = cr2cell ( 1, $i);
        $valor = $ref->[1]{$cell};
        
    };
    $i++;
    push @docs, \%hash;
} 
	for (my $b = 0; $b < scalar@docs; $b++)
	{
		
# campo organizacao esse bloco   sera feito um tratamento nos valores para que possa ficar no padrao do formulario
	my $org =($docs[$b]->{tp_org});
	$org =~ s/^\s+//;
    $org =~ s/\s+$//;
    my $tOrg = '';
    my $tOutroOrg = '';
	my $ORG =lc($org);
	my $outroOrg = "";	
		if ($ORG  ne 'og' and 
	        $ORG  ne 'ong'and 
	        $ORG  ne 'associação' and
	        $ORG  ne 'movimento'  and
	        $ORG  ne 'sindicato'  and
	        $ORG  ne ""){
		          $outroOrg = $org;
		          $org = 'Outros';
		          $tOrg = "<tipoOrganiz>".$org."</tipoOrganiz>";
	              $tOutroOrg = "<outrosTipoOrganiz>".$outroOrg."</outrosTipoOrganiz>";	
			}else{
				if ($org  eq 'OG' or 
	                $org  eq 'ONG'  ){
		                  $org = uc($org);
		                  $tOrg = "<tipoOrganiz>".$org."</tipoOrganiz>";
	                      $tOutroOrg = "";
					}elsif ($ORG  ne ""){					      
		                  $org = ucfirst($org);
		                  $tOrg = "<tipoOrganiz>".$org."</tipoOrganiz>";
	                      $tOutroOrg = "";
				}
		}
		if  ($ORG  eq ""){
		    $tOrg = "";
	        $tOutroOrg = "";
		    }

# campo tematicas abordadas esse bloco sera feito um tratamento nos valores para que possa ficar no padrao do formulario
	my $temas =($docs[$b]->{temas});
	$temas =~ s/^\s+//;
    $temas =~ s/\s+$//; 
	my $TEMAS =lc($temas);
	my $outroTemas = "";
	my $tTemas = '';
	my $tOutroTemas = '';
		
		if ($TEMAS  ne 'trabalho e renda'and 
		    $TEMAS  ne 'educação' and 
	        $TEMAS  ne 'saúde'  and 
	        $TEMAS  ne 'gênero'  and 
	        $TEMAS  ne 'diversidade sexual'   and
	        $TEMAS  ne "sexualidade"  and
	        $TEMAS  ne "acessibilidade pessoa com deficiência"  and
	        $TEMAS  ne "ambiental"  and
	        $TEMAS  ne "drogas"  and
	        $TEMAS  ne "étnico-racial"  and
	        $TEMAS  ne "religião"  and
	        $TEMAS  ne "cultura"  and
	        $TEMAS  ne "esporte e lazer"  and
	        $TEMAS  ne "direitos humanos e cidadania"  and
	        $TEMAS  ne "comunicação"  and
	        $TEMAS  ne "" ){
				   $outroTemas = ucfirst($temas);
		           $temas = 'Outros';
		           $tTemas="<tematicaAbordadas>".$temas."</tematicaAbordadas>";
	               $tOutroTemas="<outrasTematicasAbordadas>".$outroTemas."</outrasTematicasAbordadas>";
		}elsif($TEMAS  ne "" ){
				   $temas = ucfirst($temas);
		           $tTemas="<tematicaAbordadas>".$temas."</tematicaAbordadas>";
	               $tOutroTemas="";
			
			
			}		
		
			 if ($TEMAS  eq "" ){	
		           $tTemas="";
	               $tOutroTemas="";
	               }
		           
		           
# campo faixa etaria esse bloco sera feito um tratamento nos valores para que possa ficar no padrao do formulario
	my $fxE =($docs[$b]->{fx_etaria});
	my $outrasfxE = "";	
	my $tFxe ='';
	my $tOutrasfxE = "";
	$fxE =~ s/^\s+//;
	$fxE =~ s/\s+$//;
	my $FXE =lc($fxE);
	

		
		if ($FXE  ne '15 a 18 anos'and 
	        $FXE  ne '19 a 24 anos'and
	        $FXE  ne '25 a 29 anos' and 
	        $FXE  ne ""){
				   $outrasfxE= ucfirst($fxE);
		           $fxE = 'Outros';
		           $tFxe ="<faixaEtariaParticip>".$fxE ."</faixaEtariaParticip>";
	               $tOutrasfxE ="<outrosParticip>".$outrasfxE."</outrosParticip>";
		}elsif($FXE  ne ""){
				   $outrasfxE= ucfirst($fxE);
		           $fxE = 'Outros';
		           $tFxe ="<faixaEtariaParticip>".$fxE ."</faixaEtariaParticip>";
	               $tOutrasfxE =""
			}							
		 if ($FXE  eq ""){				  	      
		      $tFxe ="";
	          $tOutrasfxE ="";	           		           	           
		           }          
           
# campo quantidade de jovens que partivipa da ativiades esse bloco sera feito um tratamento nos valores para que possa ficar no padrao do formulario
	my $tegQtdJo ;
	my $qtdJo =($docs[$b]->{qt_jovens});
	$qtdJo =~ s/^\s+//;
	$qtdJo =~ s/\s+$//;
    $qtdJo =lc($qtdJo);
	
		
		if ($qtdJo eq '10 a 20'and 
	        $qtdJo eq '20 a 40'and
	        $qtdJo eq 'mais de 40' and 
	        $qtdJo  eq ""){
				
				$tegQtdJo =  "<jovensParticipAtividOrganiz>".$qtdJo."</jovensParticipAtividOrganiz> "; 
		
		        
	    } else {	

			    $tegQtdJo =  "";		         
		 }      
	      	           
										
# campo 4.1. Onde acontecem as atividades da Organização esse bloco sera feito um tratamento nos valores para que possa ficar no padrao do formulario
	my $atv =($docs[$b]->{local_atv});
	my $outroAtv = "";
	my $tAtv='';
	my $tOutroAtv ='';
    $atv =~ s/^\s+//;
    $atv =~ s/\s+$//; 	
	my $ATV =lc($atv);	
	
		if ($ATV  ne 'escola'and
		    $ATV  ne 'sede própria'and 
	        $ATV  ne 'casa de amigos' and 
	        $ATV  ne 'igreja' and 
	        $ATV  ne 'universidade'  and
	        $ATV  ne "" ){				
				   $outroAtv  = ucfirst($atv);				   
		           $atv = 'Outros';		
		           $tAtv=     "<ondeAcontecemAtividOrganiz>".$atv."</ondeAcontecemAtividOrganiz>";
	               $tOutroAtv="<outrosAtividorganiz>".$outroAtv ."</outrosAtividorganiz>"; 	
		}elsif ($ATV ne ""){
			     $atv = ucfirst($atv);
		         $tAtv="<ondeAcontecemAtividOrganiz>".$atv."</ondeAcontecemAtividOrganiz>";;
	             $tOutroAtv="";               
		         
		         }
		
		if ($ATV eq ""){
		         $tAtv='';
	             $tOutroAtv='';               
		         
		         }
		
# campo 4.2. Com que freqüência costuma se reunir esse bloco sera feito um tratamento nos valores para que possa ficar no padrao do formulario
	my $freReun =($docs[$b]->{freq_reuniao});
	$freReun =~ s/^\s+//;
    $freReun =~ s/\s+$//;           
	my $FREREUN =uc($freReun);
	my $outroFreReun = "";
		
		if ($FREREUN  ne 'DIARIAMENTE'and
		    $FREREUN  ne 'SEMANALMENTE'and
	        $FREREUN  ne 'QUIZENALMENTE' and 
	        $FREREUN  ne  'MENSALMENTE' and 
	        $FREREUN  ne "" ){
				   $outroFreReun  = ucfirst($freReun);
		           $freReun = 'Outro';          
		}								        
				 if ($FREREUN  eq "" ){  $outroFreReun  = ' ';
		           $freReun = 'Outro'; }
		           
# tratamento no campo data para adequar aos padrao do sedna e do formulario 		           
my $dateTime = $docs[$b]->{data};
$dateTime  =~ s/^(.*)\/(.*)\/(.*)/$3-$2-$1/go;

    my $xml .= "
<orgMovEst xmlns=\"http://schemas.fortaleza.ce.gov.br/acao/coordenadoriajuventude-cad-org_mov_est.xsd\">
<identificOrganiz>
	<organizacao>".$docs[$b]->{organizacao}."</organizacao>
	<endereco>".$docs[$b]->{endereco}."</endereco>
	<bairro>".$docs[$b]->{bairro}."</bairro>
	<cidade>".$docs[$b]->{cidade}."</cidade>
	<cep>".$docs[$b]->{cep}."</cep>
	<fone>".$docs[$b]->{fone}."</fone>
	<email>".$docs[$b]->{email}."</email>
	<site>".$docs[$b]->{site}."</site>
	<blog>".$docs[$b]->{blog}."</blog>
	<anoFundacao>".$docs[$b]->{ano_fundacao}."</anoFundacao>
	<cnpj>".$docs[$b]->{cnpj}."</cnpj>
</identificOrganiz>
<infoSobreOrganiz>
    ".$tOrg."
    ".$tOutroOrg."
    ".$tTemas.";
	".$tOutroTemas.";
	<atividadesDesenvolvidas>".$docs[$b]->{atividade}."</atividadesDesenvolvidas>
	<territorioAtuacao>".$docs[$b]->{territ_atua}."</territorioAtuacao>
</infoSobreOrganiz>
<participantes>
	<publicoAlvo>".$docs[$b]->{pub_alvo}."</publicoAlvo>
    ".$tFxe."
	".$tOutrasfxE."
	".$tegQtdJo."
</participantes>
<formaOrganiz>
	".$tAtv."
	".$tOutroAtv."
	<frequenciaCostumaReunir>".$freReun."</frequenciaCostumaReunir>
	<outrosFrenquenc>".$outroFreReun ."</outrosFrenquenc>
	<nomeResponsavel>".$docs[$b]->{resp}."</nomeResponsavel>
	<funcao>".$docs[$b]->{funcao}."</funcao>
	<telefone>".$docs[$b]->{fone_resp}."</telefone>
	<email>".$docs[$b]->{email_resp}."</email>
	<data>".$dateTime."</data>
</formaOrganiz>
</orgMovEst>
";
 
# chamada dos metodos passando os valores aos atributos 
my $controle = criaProntuario($docs[$b]->{organizacao});
inserirDocumento( $xml, $controle);

}

#conexao com o banco sedna de uso
#my $sedna = Sedna->connect('172.31.2.12', 'AcaoDbHom', 'acao', 'acao');
#$sedna->setConnectionAttr(AUTOCOMMIT => Sedna::SEDNA_AUTOCOMMIT_OFF() );

{   package DumbUser;
    use Moose;
    sub memberof {[ Acao->config->{roles}{dossie}{criar}, Acao->config->{roles}{volume}{criar} , Acao->config->{roles}{documento}{criar}]}
    sub uid {'importacao.juventude'}
    sub id {'importacao.juventude'}
    sub cn {'Importação.juventude'}
}

# chamada do método criaProntuario passando os respectivos paramentros 
sub criaProntuario{
        my($nome, $representaVolumeFisico, $classificacoes,$autorizacoes) = (shift , 0, {'classificacao' => ["cn=Juventude,dc=assuntos,dc=diretorio,dc=fortaleza,dc=ce,dc=gov,dc=br"]}, $auth );
        my $ip = '127.0.0.1';
	my $localizacao = 'dc=local,dc=diretorio,dc=fortaleza,dc=ce,dc=gov,dc=br';	
        my $id_volume = 'volume-6EA87E3A-B18C-11E1-AC28-A36EE91B6C0F';
        my $herdar_author = '1';
        my $dossie_fisico = 0;
	$nome =~ tr/a-zàáâãäåæçèéêëìíîïðñòóôõöøùúûüý/A-ZÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝ/;
        my $octets_nome =  $nome;

        
        my $model = Acao::Model::Dossie->new(user => DumbUser->new(), sedna => Acao->model('Sedna'), dbic => Acao->model('DB')->schema);
        my $collection = $model->criar_dossie( {ip=>$ip, nome=>$octets_nome, id_volume =>$id_volume, dossie_fisico=>$dossie_fisico, classificacoes=>$classificacoes, 
																							localizacao=>$localizacao, herdar_author=>$herdar_author, autorizacoes=>$autorizacoes});
        warn "collection $collection criada com sucesso!";
        return $collection;
    }
# chamada do método inserirDocumento passando os respectivos paramentros e inserindo dados de acordo com o padrao do documento 
sub inserirDocumento{

	    my($xml, $controle) = @_;
        my ($representaVolumeFisico, $classificacoes,$autorizacoes) = ( 0, {'classificacao' => ["cn=Juventude,dc=assuntos,dc=diretorio,dc=fortaleza,dc=ce,dc=gov,dc=br"]}, $auth );
        my $ip = '127.0.0.1';
        my $id_volume = 'volume-6EA87E3A-B18C-11E1-AC28-A36EE91B6C0F';
        my $xsdDocumento ='http://schemas.fortaleza.ce.gov.br/acao/coordenadoriajuventude-cad-org_mov_est.xsd';
        my $representaDocumentoFisico = 0;
        my $herdar_author = '1';
	my $localizacao = 'dc=local,dc=diretorio,dc=fortaleza,dc=ce,dc=gov,dc=br';	
        my $id_Prontuario ='$collection';
        my $id_documento ='';       
        my $dossie_fisico = 0;
        my $model = Acao::Model::Documento->new(user => DumbUser->new(), sedna => Acao->model('Sedna'), dbic => Acao->model('DB')->schema);
        my $cDoc = $model->inserir_documento( $ip, $xml, $id_volume, $controle, $xsdDocumento, $representaDocumentoFisico, $herdar_author, $autorizacoes, $id_documento);
        warn " Documento $cDoc inserido com sucesso!";                                
                               
 }

