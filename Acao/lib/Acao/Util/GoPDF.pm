package Acao::Util::GoPDF;
use 5.10.0;
use Moose;
use XML::LibXML;
use Data::Dumper;
use PDF::Report;
use utf8;
use Clone qw(clone);
use constant XSD_NS => 'http://www.w3.org/2001/XMLSchema';

sub genPDF {
    my ( $xsd, $xml ) = @_;
    my $schemadoc    = XML::LibXML->load_xml( string => $xsd );
    my $schemabaseel = $schemadoc->getDocumentElement;
    my $targetns     = $schemabaseel->getAttribute('targetNamespace');
    my ( $stack, $stelements ) = ( [], [] );
    my $level = 0;

    traverse_schema_to_pdf( $schemabaseel, $targetns,
        $schemabaseel, $xml, $level, $stack, $stelements );
    return create_pdf($stelements);
}


sub traverse_schema_to_pdf {
    my ( $baseschemael, $targetns, $node, $xml, $level, $stack, $stelements ) = @_;
    return unless ref $node eq 'XML::LibXML::Element';

    given ( $node->localname ) {
        when ('schema') {
            $baseschemael = $node;
            $targetns     = $node->getAttribute('targetNamespace');
            foreach my $el ( $node->childNodes ) {
                $level++;
                traverse_schema_to_pdf( $baseschemael, $targetns, $el, $xml, 
                    $level, [ $baseschemael, $stack ], $stelements );
                $level--;
            }
        }
        when ('element') {
            my ($innertype);
            if ( my $type = $node->getAttribute('type') ) {

                # inline type declaration...
                my ( $valuens, $valuensprefix, $valuestr );
                if ( $type =~ /\:/ ) {
                    ( $valuensprefix, $valuestr ) = split /:/, $type;
                }
                else {
                    $valuensprefix = '';
                    $valuestr      = $type;
                } 
                $valuens = resolve_ns( $node, $stack, $valuensprefix );
                if ( $valuens eq XSD_NS ) {
                    my $into = build_xpath( [$node, $stack, $xml, $level ] );
                    #put_file( '-'x$level . $into->{name} . ": " . $into->{value} . "\n");

                    # este cara é um simple type.
                    push @$stelements, $into;
                    return;
                }
                elsif ( $valuens eq $targetns ) {
                    # tenho que achar o tipo no próprio schema
                    ($innertype) =
                      grep {
                             ref $_ eq 'XML::LibXML::Element'
                          && $_->localname =~ /(complex|simple)Type/
                          && $_->getAttribute('name') eq $valuestr
                      } $baseschemael->childNodes;
                }
                else {
                    die "References to external schemas not yet implemented";
                }
            }
            else {
                ($innertype) =
                  grep {
                    ref $_ eq 'XML::LibXML::Element'
                      && $_->localname =~ /(complex|simple)Type/
                  } $node->childNodes;
            }
            if ( $innertype->localname eq 'simpleType' ) {
                my $into = build_xpath( [$node, $stack, $xml, $level ] );
                push @$stelements, $into;
                return;
            }
            else {
                my $inner = [ $node, $stack ];
                my $into = build_xpath( [$node, $stack, $xml, $level ] );
                foreach my $el ( $innertype->childNodes ) {
                    $level++;
                    traverse_schema_to_pdf( $baseschemael, $targetns, $el, $xml, 
                        $level, [ $innertype, $inner ], $stelements );
                    $level--;
                }
                push @$stelements, close_xpath();
            }
        }
        when ('sequence') {
            my $into = build_xpath( [$node, $stack, $xml, $level ] );
            if( ($into->{maxOccurs} != 0) ) {
                my $xml_espec = getValue( $into->{path}, $xml);
                if( defined $xml_espec && scalar @{$xml_espec} > 0) {
                    for my $ele (@{$xml_espec} ) {

                        if( not defined $ele->{'seq_nome'} ) {                            
                            push @{$stelements}, $into;
                            my $nxml = clone $xml;
                            &t( $nxml, $ele, $into->{path});

                            foreach my $el ( $node->childNodes ) {
                                $level++;
                                traverse_schema_to_pdf( $baseschemael, $targetns, $el, $nxml, 
                                    $level, [ $node, $stack ], $stelements );
                                $level--;
                            }
                            push @$stelements, close_xpath();
                        }
                        else {
                            foreach my $key (keys %{$ele} ) {
                                push @{$stelements}, $into;
                                my $nxml = clone $xml;
                                &t( $nxml, $ele->{$key}[0], $into->{path});

                                foreach my $el ( $node->childNodes ) {
                                    $level++;
                                    traverse_schema_to_pdf( $baseschemael, $targetns, $el, $nxml, 
                                        $level, [ $node, $stack ], $stelements );
                                    $level--;
                                }
                                push @$stelements, close_xpath();
                            }
                        }
                    }
                }
            } else {
                push @$stelements, $into;

                foreach my $el ( $node->childNodes ) {
                    $level++;
                    traverse_schema_to_pdf( $baseschemael, $targetns, $el, $xml, 
                        $level, [ $node, $stack ], $stelements );
                    $level--;
                }
            } #else
        }
    }
}

sub resolve_ns {
    my ( $node, $stack, $prefix ) = @_;
    my $attrname = $prefix ? 'xmlns:' . $prefix : 'xmlns';
    if ( my $value = $node->getAttribute($attrname) ) {
        return $value;
    }
    elsif ( ref $stack eq 'ARRAY'
        && scalar @$stack == 2 )
    {
        return resolve_ns( $stack->[0], $stack->[1], $prefix );
    }
    else {
        die "prefix $prefix lookup failed.";
    }
}

sub build_xpath {
    my $stack = shift;
    my ( $node, $outer, $xml, $level ) = @$stack;
    my $outer_info = { path => '' };
    $outer_info = build_xpath($outer) if $outer;

    if ( ref $node eq 'XML::LibXML::Element'
        && $node->localname eq 'element' )
    {
        my $label = get_label($node);
        $label =~s/\t/ /gs;
        $label =~s/ +/ /gs;

        my $complabel =
            $outer_info->{completelabel}
          ? $outer_info->{completelabel} . ' - ' . $label
          : $label;
        my $type = get_type($node);
        my $pathx = $outer_info->{path} . '/' . $node->getAttribute('name');

        my $maxOccurs = $node->getAttribute('maxOccurs');
        my $value = &getValue( $pathx, $xml );

        return {
            type  => (defined $type ? $type : ''),
            name  => $node->getAttribute('name'),
            path  => $pathx,
            label => $label,
            level => $level,
            value => $value,
            maxOccurs => ( defined $maxOccurs ? $maxOccurs : 0),
            completelabel => $complabel
        };
    }
    else {
        return $outer_info;
    }
}

sub getValue {
    my $path = shift;
    my $xml = shift;
    my @path_arr = split('/', $path);

    shift @path_arr;
    shift @path_arr;
    return get_hash_path( $xml, @path_arr );
}

sub t {
    my $nxml = shift;
    my $nv = shift;
    my $path = shift;

    my @p = split /\//o, $path;
    shift @p;
    shift @p;
    &walk($nxml, $nv, \@p);
}

sub walk {
    my $nxml = shift;
    my $newvalue = shift;
    my $p = shift;
    if (scalar @{$p} == 1) {
        my $key = shift @{$p};
        $nxml->{$key} = $newvalue;
    } else {
        my $key = shift @{$p};
        &walk($nxml->{$key}, $newvalue, $p);
    }
}

sub get_hash_path {
    my ($data_ref, @path) = @_;
    return $data_ref unless scalar @path;
    my $return_value = $data_ref->{ $path[0] };
    for (1 .. (scalar @path - 1)) {
        next unless ref $return_value eq 'HASH';
        $return_value = $return_value->{ $path[$_] };
    }
    return $return_value;
}

sub close_xpath {
    return {
        type => 'close',
        name => 'close',
        label => 'close',
        level => undef,
        value => undef
    }
}

sub get_label {
    my $node = shift;
    my ($ann) =
      grep { ref $_ eq 'XML::LibXML::Element' && $_->localname eq 'annotation' }
      $node->childNodes;
    return '' unless $ann;
    my ($app) =
      grep { ref $_ eq 'XML::LibXML::Element' && $_->localname eq 'appinfo' }
      $ann->childNodes;
    return '' unless $app;
    my ($lab) =
      grep { ref $_ eq 'XML::LibXML::Element' && $_->localname eq 'label' }
      $app->childNodes;
    my ($txt) = grep { ref $_ eq 'XML::LibXML::Text' } $lab->childNodes;
    return '' unless $txt;
    return $txt->data;
}

sub get_type {
    my $node        = shift;
    my $direct_type = $node->getAttribute('type');
    return $direct_type if $direct_type;

    my ($sty) =
      grep { ref $_ eq 'XML::LibXML::Element' && $_->localname eq 'simpleType' }
      $node->childNodes;
    return unless $sty;

    my ($def) = grep { ref $_ eq 'XML::LibXML::Element' } $sty->childNodes;
    return $def->getAttribute('base');
}


sub create_pdf{
    my $AoH = shift;
    my @arr = @{$AoH};
    my $file = 'pref.pdf';
    my $current_page = 0;
    my %page;

    my $nivel = 0;    
    my $i = 1;
    my $j = 0;
    my $font_size = 12;
    my $page_position = 750;
    my $end_page = 590;
    my $txt;

    my $textPosX = 10;
    my $textPosY = 810;
    my $textWidth = 220;
    my $textWidthTitle = 200;
    my $textSize = 12;
    my $txt_space_line = 3;
    my $space_between = 10;
    my $color_even = '#dddddd';

    my $pdf = new PDF::Report(PageSize => "A4", 
                              PageOrientation => "Portrait");

    my ($pagewidth, $pageheight) = $pdf->getPageDimensions();
    #print "Page size: $pagewidth, $pageheight\n";

    $pdf->newpage(1);
    $pdf->openpage;
    $pdf->setFont('Arial');
    $pdf->setSize($textSize);
    $pdf->setAddTextPos( $textPosX, $textPosY );
    my ( $xPos, $yPos )  = $pdf->getAddTextPos();
    #print "$xPos, $yPos\n";

    #for $i (0 .. 358) {
    for $i (0 .. $#arr ) {
        my ( $xPos, $yPos )  = $pdf->getAddTextPos();

        #Define o número da página
        if( $arr[$i]->{type} ne 'close' ) {
            if( (!defined $arr[$i]->{level}) ) {
                #############################################
                #####    No caso de abertura de div     #####
                #############################################

                my ( $xPos, $yPos )  = $pdf->getAddTextPos();
                #print "Div: $i: $xPos\n";
                my $textWidthTitle = $pagewidth - ($nivel * 10) - 4;
                my $text_label = &textWrapper( $pdf, $arr[$i]->{label}, $textWidthTitle);

                my @cut = split(/\n/, $text_label);
                my $gt = 0;
                for $j (0 .. $#cut) {
                  if ( $gt < $pdf->getStringWidth( $cut[$j])) {
                    $gt = $pdf->getStringWidth( $cut[$j]);
                  }
                }

                my $count_geral = 0;
                $count_geral++ while $text_label =~ /\n/g;

                if( ($yPos - ($textSize * ($count_geral+3) )) <= 0 ) {
                    $pdf->newpage();
                    $pdf->openpage;
                    $yPos = $pageheight - $textSize;
                }                
                
                $pdf->setAddTextPos( $textPosX + $nivel * 10, $yPos );
                
                #criando as linhas dos niveis anteriores
                for $j (0 .. $nivel - 1 ) {
                    $pdf->drawLine( 3 + ($j * 10),          #x1 - larg
                                    $yPos + $textSize,      #y1 - altura
                                    3 + ($j * 10),          #x2
                                    $yPos - ($textSize * $count_geral) ); #y2

                    $pdf->drawLine( $pagewidth - (3 + ($j * 10)), 
                                    $yPos + $textSize, 
                                    $pagewidth - (3 + ($j * 10)), 
                                    $yPos - ($textSize * $count_geral) );
                }


                #criando a linha de fechamento lateral
                $pdf->drawLine( 3 + ($nivel * 10),      #x1 - larg
                                $yPos + ($textSize/2),  #y1 - altura
                                3 + ($nivel * 10),      #x2
                                $yPos - ($textSize * $count_geral) ); #y2

                $pdf->drawLine( $pagewidth - (3 + ($nivel * 10)), 
                                $yPos + ($textSize/2), 
                                $pagewidth - (3 + ($nivel * 10)), 
                                $yPos - ($textSize * $count_geral) );
                #linha da esquerda ao texto
                $pdf->drawLine( 
                        (3 + ($nivel * 10) ), 
                        $yPos + ($textSize/2), 
                        $textPosX + $nivel * 10 - $txt_space_line, 
                        $yPos + ($textSize/2) );
                #linha da direita ao texto
                $pdf->drawLine( 
                        $textPosX + $nivel * 10 + $gt + $txt_space_line, 
                        $yPos + ($textSize/2), 
                        $pagewidth - (3 + ($nivel * 10)), 
                        $yPos + ($textSize/2) );
                
                #aplicação do texto
                $pdf->addText($text_label);
                $pdf->setAddTextPos( $textPosX, $yPos - ($textSize * ($count_geral+1)) );

                $nivel++;
            } else {
                ######################################
                #####    No caso de elemento     #####
                ######################################
                my ( $xPos, $yPos )  = $pdf->getAddTextPos();
                #print "El $i: $xPos\n";

                my $textWidthValue = $pagewidth - $textWidth - ($nivel * 10) - 10 - $space_between;
                my $text_label = &textWrapper( $pdf, $arr[$i]->{label}, $textWidth);
                my $label_count = 0;
                $label_count++ while $text_label =~ /\n/g;

                my $text_value = '';

                if( $arr[$i]->{type} ne 'xs:date') {
                    $text_value = &textWrapper( $pdf, $arr[$i]->{value}, $textWidthValue);
                } else {
                    my $date = $arr[$i]->{value};
                    if(defined $date) {
                        $date =~ s{(\d+)-(\d+)-(\d+)}{$3/$2/$1};
                    }
                    $text_value = &textWrapper( $pdf, $date, $textWidthValue);
                }

                my $value_count = 0;
                if (defined $text_value) {
                    $value_count++ while $text_value =~ /\n/g;
                }

                my $count_geral = ( $label_count > $value_count ? $label_count : $value_count );

                #print "$yPos - ($textSize * $count_geral $value_count $label_count)\n ";
                if( ($yPos - ($textSize * ($count_geral+3) )) <= 0 ) {
                    $pdf->newpage();
                    $pdf->openpage;
                    $yPos = $pageheight - $textSize;
                }

                #criando as linhas dos niveis anteriores
                for $j (0 .. $nivel - 1 ) {
                    $pdf->drawLine( 3 + ($j * 10),          #x1 - larg
                                    $yPos + $textSize,      #y1 - altura
                                    3 + ($j * 10),          #x2
                                    $yPos - ($textSize * $count_geral) ); #y2

                    $pdf->drawLine( $pagewidth - (3 + ($j * 10)), 
                                    $yPos + $textSize, 
                                    $pagewidth - (3 + ($j * 10)), 
                                    $yPos - ($textSize * $count_geral) );
                }

                #Colorindo os campos pares
                if( $i%2 == 0) {
                    $pdf->shadeRect( ($nivel * 10) - 2,
                                     $yPos + $textSize - 2,
                                     $pagewidth - (3 + $nivel * 10) + 2,
                                     $yPos - ($textSize * $count_geral) - 2,
                                     $color_even);
                }

                if( $arr[$i]->{type} ne 'xs:boolean') {
                  $pdf->setAddTextPos( $nivel * 10, $yPos );
                  #print "$nivel * 10, $yPos, $textWidth, $textWidthValue <---\n";
                  $pdf->addText($text_label);
                  $pdf->setAddTextPos( $nivel * 10, $yPos );
                  #print "$nivel * 10, $yPos <------\n";
                  $pdf->addText($text_label);

                  $pdf->setAddTextPos( ($nivel * 10) + $textWidth + $space_between, $yPos );
                  $pdf->addText($text_value);
                } else {
                    #TODO: Preciso fazer o tratamento do date/time
                    $pdf->setAddTextPos( $nivel * 10, $yPos );
                    #Se for Boolean o tratamento é diferente..
                    $pdf->drawRect( ($nivel*10), $yPos + $textSize - $txt_space_line, ($nivel*10) + $textSize - $txt_space_line, $yPos);
                    
                    $pdf->setAddTextPos( $nivel * 10 + ($textSize * 1.2) - $txt_space_line, $yPos );
                    $pdf->addText($text_label);
                    $pdf->setAddTextPos( $nivel * 10 + ($textSize * 1.2) - $txt_space_line, $yPos );
                    $pdf->addText( $text_label );

                    if( $arr[$i]->{value} == 1) {
                        $pdf->drawLine( ($nivel*10), $yPos + $textSize - $txt_space_line, ($nivel*10) + $textSize - $txt_space_line, $yPos);
                        $pdf->drawLine( ($nivel*10) + $textSize - $txt_space_line, $yPos + $textSize - $txt_space_line, $nivel*10, $yPos);
                    }
                }
                my ( $xPosNew, $yPosNew )  = $pdf->getAddTextPos();
                #print "El $i: $yPos -> $yPosNew\n";
                #print "$text_label\n";
                $pdf->setAddTextPos( $textPosX, $yPos - ($textSize * ($count_geral+1) ));
            }

            
        } else {
            #############################################
            #####    No caso de fechar elemento     #####
            #############################################
            
            #criando as linhas dos niveis anteriores
            if( ($yPos - ($textSize * 2)) <= $textSize ) {
                $pdf->newpage();
                $pdf->openpage;
                $yPos = $pageheight - $textSize;
            }    
                    
            for $j (0 .. $nivel - 2 ) {
                $pdf->drawLine( 3 + ($j * 10),       #x1 - larg
                                $yPos + $textSize,   #y1 - altura
                                3 + ($j * 10),       #x2
                                $yPos );             #y2

                $pdf->drawLine( $pagewidth - (3 + ($j * 10)), 
                                $yPos + $textSize, 
                                $pagewidth - (3 + ($j * 10)), 
                                $yPos );
            }
            $nivel--;

            #criando a linha de fechamento lateral
            $pdf->drawLine( 3 + ($nivel * 10),      #x1 - larg
                            $yPos + ($textSize/2),  #y1 - altura
                            3 + ($nivel * 10),      #x2
                            $yPos + $textSize );    #y2

            $pdf->drawLine( $pagewidth - (3 + ($nivel * 10)), 
                            $yPos + ($textSize/2), 
                            $pagewidth - (3 + ($nivel * 10)), 
                            $yPos + $textSize );

            #linha da direita ao texto
            $pdf->drawLine( 
                    (3 + ($nivel * 10) ), 
                    $yPos + ($textSize/2), 
                    $pagewidth - (3 + ($nivel * 10)), 
                    $yPos + ($textSize/2) );

            
            $pdf->setAddTextPos( $textPosX, $yPos - $textSize );
        }
    }
    return $pdf->Finish();    
}

sub textWrapper {
    my $pdf = shift;
    my $text = shift;
    my $size = shift;

    if( !$text ) {
        return $text;
    }

    my @cut = split(/\s/, $text);
    my $out = '';
    my $space_size = $pdf->getStringWidth( ' ' );
    my $line_size = 0;
    
    for my $j (0 .. $#cut) {
        my $current_size = $pdf->getStringWidth( $cut[$j] );
        if( ($line_size + $space_size + $current_size) > $size ) {
            if ($out eq '') {
                $out = $cut[$j];
            } else {
                if(defined $cut[$j]) {$out .= "\n" . $cut[$j];}
            }
            $line_size = $current_size;
        } else {
            if ($out eq '') {
                $out = $cut[$j];
                $line_size += $current_size;
            } else {
                if($cut[$j]) {
                    $out .= " " . $cut[$j];
                    $line_size += $space_size + $current_size; 
                }
            }
        }
    }
    return $out;  
}

sub put_file {
    my $in = shift;
    open  FILE, ">>/tmp/logz" or die $!;
    print FILE $in;
    close FILE;
}

sub cor {
    my $color = shift;
    given ($color) {
        when ('end') {return "\033[0m";}
        when ('black') {return "\033[90m"; }
        when ('red') {return "\033[91m";}
        when ('green') {return "\033[92m"; }
        when ('yellow') {return "\033[93m";}
        when ('blue') {return "\033[94m";}
        when ('purple') {return "\033[95m";}
        when ('cyan') {return "\033[96m";}
        when ('gray') {return "\033[97m";}
        when ('white') {return "\033[98m";}
        when ('grayb') {return "\033[100m";}
        when ('redb') {return "\033[101m";}
        when ('greenb') {return "\033[102m";}
        when ('yellowb') {return "\033[103m";}
        when ('blueb') {return "\033[104m"; }
        when ('purpleb') {return "\033[105m"; }
        when ('cyanb') {return "\033[106m"; }
        when ('grayb') {return "\033[107m"; }
        when ('cls') {return "\033[2J";}
        when ('bold') {return "\033[1m"; }
        when ('endbold') {return "\033[21m";}
        when ('blink') {return "\033[5m";}
        when ('endblink') {return "\033[25m";}
    }
}

1;
