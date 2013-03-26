#!/usr/bin/perl
use strict;
use warnings;

my $file = $ARGV[0] or die "Arquivo não encontrado\n";
my $line;

open(my $data, '<', $file) or die "Não pode abrir '$file' $!\n";

sub init{
    my $create;
    my @coluna = getHead();
    my $ultimocaracter = getLastCaracter($line);
    if (getLastCaracter() eq ';'){
        $create = 'CREATE TABLE '. $ARGV[1] . '(' . join(" character varying not null default 0,\n", @coluna ) . " vazio character varying not null default 0,\n)";
    }else{
        $create = 'CREATE TABLE '. $ARGV[1] . '(' . join(" character varying not null default 0,\n", @coluna ) . ')';        
    }
    warn $create . "SERVER arquivo
   OPTIONS (filename '/media/upload/SEMAS/FOLHAS/2012/MAI/R007C_0512_0694_CE_2304400.CSV',format 'csv',delimiter ';' ,header 'true');
ALTER FOREIGN TABLE cadastro_unico.ftb_folhapag_mai2012
  OWNER TO dw;";
}

#pega o cabeçalho do CSV
sub getHead{
    my @fields;
    my $end = 0;
    while ($line = <$data>) {
        @fields = split ";" , $line;
        last;
    }
    @fields = clearArray(@fields);
    return @fields;
}

#retira espaços no início e fim de uma string
sub removeSpace{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

#verifica qual o ultimo caractere em uma string
sub getLastCaracter{
   my $string = @_;
   my $ultimo = substr(removeSpace($string), removeSpace(length($string)) -1 );
   return $ultimo;
}


#tira os espaços em cada posição do array
sub clearArray{
    my @array = @_;
    for (my $i = 0; $i<scalar(@array); $i++){
        $array[$i] = removeSpace($array[$i]);
    }
    return @array;
}

init();
