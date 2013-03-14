#!/usr/bin/perl

use utf8;
use DBI;
use Data::Dumper;
use XML::Simple;
use Sedna;
use Storable;
use XML::Compile::Schema;
use XML::Compile::Util qw(pack_type);
use strict;
$|=6;

#PARAMETROS: 0 - ID_VOLUME, 
#            1 - PATH PARA O XSD, 
#            2 - TARGETNAMESPACE, 
#            3 - NÓ PAI, 
#            4 - ESCHEMA.NOME TABELA
#            5 - TIPO OPERACAO([1] CRIAR TABELA OU [2] POVOAR)

my $xsd = $ARGV[1];


sub result {
	my ($log) = shift;
    open(LOG,'>> relatório_viladomar.csv');
    print LOG $log ;
    close(LOG);   
    # return print $log;
}
    

my ($url, $dbname, $login, $pass) = ('172.30.116.137', 'AcaoDb', 'acao','12345') ;

my $s = Sedna->connect($url,$dbname,$login,$pass);

$s->begin;

my $xq = 'declare namespace cdig = "http://schemas.fortaleza.ce.gov.br/acao/controledigitacao.xsd";
declare namespace cadb = "http://schemas.fortaleza.ce.gov.br/habitafor/viladomar-cadernob.xsd";
declare namespace cada = "http://schemas.fortaleza.ce.gov.br/habitafor/viladomar-cadernoa.xsd";

for $x in collection("leitura-1")/cdig:registroDigitacao/cdig:documento[cdig:estado/text() eq "Aprovado"] 
let $docs :=  collection("leitura-2")/cdig:registroDigitacao/cdig:documento[cadb:formularioPrincipal/text() eq $x/cdig:controle/text() and 
                       cadb:informante/text() eq "Chefe" and cdig:estado/text() eq "Aprovado"]
                      

return (
      concat(
                  $x/cdig:conteudo/cada:formCadernoA/cada:identificacao/cada:codigoPMF/text(), ";",
                  $x/cdig:controle/text(), ";",
                  $x/cdig:conteudo/cada:formCadernoA/cada:identificacao/cada:titularBeneficiario/text(), ";",
                  $x/cdig:conteudo/cada:formCadernoA/cada:enderecoImovel/cada:logradouro/text(), ";",
                  $x/cdig:conteudo/cada:formCadernoA/cada:enderecoImovel/cada:numero/text(), ";",
                  $x/cdig:conteudo/cada:formCadernoA/cada:enderecoImovel/cada:complemento/text(), ";",
                  $x/cdig:conteudo/cada:formCadernoA/cada:enderecoImovel/cada:telefone/text(), ";",
                  $docs/cdig:conteudo/cadb:formCadernoB/cadb:composicaoFamiliar/cadb:rg/text(), ";",
                  $docs/cdig:conteudo/cadb:formCadernoB/cadb:composicaoFamiliar/cadb:cpf/text(), ";",
                  $docs/cdig:conteudo/cadb:formCadernoB/cadb:composicaoFamiliar/cadb:nis/text()
                 )

      )

';

$s->execute($xq);
result("Codigo PMF;Controle;Titular;Logradouro;número;complemento;telefone;rg;cpf;nis\n");
while ($s->next()) {
	result($s->getItem())
}



$s->commit;



