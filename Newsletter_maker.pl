#!/usr/bin/perl
######################################################################
# Probando...
# Todavia es bastante chiotto el asunto, pero va queriendo.
######################################################################
use Getopt::Std;
use Pod::Usage;
use autodie;
use feature         q|say|;
use Text::Template;
use POSIX           q|strftime|;

my $debug          = 0;
my %opts           = ();
my %coso_loco      = ();
my $t_banana       = strftime( "%d_%B_%Y_%H_%M_%S", localtime( time() ) );
my $salida_archivo = $t_banana . 'Newsletter_premailer.html';
my $cifrado_enter  = '__ENTER__';
my $cifrado_br     = '___BR___';
say "El archivo de salida es: $salida_archivo" if $debug;
my $salida_archivo_perl         = $t_banana . 'Newsletter_WebFormat.html';
my $salida_archivo_carpeta_perl = $salida_archivo_perl;

##################
# Agregado en v2 #
##################
# Esta variable corresponde a una linea el el archivo config con el nombre de la
# carpeta a crear en donde poner los dos archivos de salida.
my $carpeteame_esta = 'NEWSLETTER_DIR';
my $carpete         = '.';

getopts( 'hdt:c:', \%opts );
$debug = $opts{d};
ayudas() if $opts{h};

# Este programa __NECESITA__ que se le pasen los argumentos -t y -c.
ayudas() unless $opts{t};
ayudas() unless $opts{c};

#Chequeo simple de archivillos...
die "Alguno o todos los archivos especificados no existen. 
Error Grave y vertigo en el upite. 
FIN" unless ( -e $opts{t} and -e $opts{c} );

# Abrir template.
my $template = Text::Template->new(
    SOURCE     => "$opts{t}",
    DELIMITERS => [ '{-----', '-----}' ]
);

# Abrir archivo configs.
open( COSO, '<', "$opts{c}" );

# Leer gilada
while (<COSO>) {
    my $ln = $_;
    next if $ln =~ m/^$/g;
    my ( $variable, $valor ) = $ln =~ m/^\s*(.+)\s*=\s*(.+)$/ig;
    say "_ $variable _ -> $valor" if $debug;

    # Esto va a ser usado despues tambien: sacar comillas y parrafear...
    my $valor_bb     = sacar_comillas($valor);
    my $valor_limpio = $valor_bb;
    ##################
    # Agregado en v2 #
    ##################
    if ( $variable eq $carpeteame_esta ) {
        $valor_bb =~ s/\s+/_/g;
        say "valor_bb == $valor_bb" if $debug;
        $carpete = hacer_carpeta_salida($valor_bb);
        next;
    }

    # Agregado para parrafear campos largos.
    if ( $valor_limpio =~ m/__ENTER__|___BR___/g ) {
        say "El contenido del campo $variable tiene __ENTER__, no?" if $debug;
        $valor_limpio = reemplazar_enters($valor_bb);
        my @pss = split( '\n', $valor_limpio );
        my $final_stringy = '';
        foreach my $pz (@pss) {
            if ( $pz =~ m/^$/g ) {
                $pz = '&nbsp;';
                $final_stringy .= parrafear( $pz );
                next;
            } else {
                my $ds = parrafear($pz);
                say "$ds" if $debug;
                $final_stringy .= linkeame_el_texto($ds);
                next;
            }
        }
        say "FINAL DEL NEO PARRAFO == $final_stringy" if $debug;
        $coso_loco{$variable} = $final_stringy;
        next;
    }
    if ( $variable =~ m/^(P\w?\d+)$/g ) {
        $valor_limpio = parrafear(linkeame_el_texto($valor_bb));
        $coso_loco{$variable} = $valor_limpio;
        next;
    }
    $coso_loco{$variable} = linkeame_el_texto(boldear($valor_limpio));
}

# Hacer la cosa.
my $final = $template->fill_in( HASH => \%coso_loco );

# Imprimir y fin.
if ( defined $final ) {
    say "----------------", "$final", "------------------" if $debug;
    unless ( $carpete eq '.' ) {
        $salida_archivo_carpeta_perl = $carpete . '/' . $salida_archivo_perl;
    }
    open( SALIDA, '>', $salida_archivo_carpeta_perl );
    say $salida_archivo_carpeta_perl if $debug;
    print SALIDA $final;

    # Ahora usar premailer en toooooodo lo que se hizo... no muy elegante pero
    # efectivo (y bastante choto).
    premailear();
}
else {
    die "Couldn't fill in template: $Text::Template::ERROR";
}

######################################################################
# SUbs
######################################################################
sub sacar_comillas {
    my $strng = shift;
    say "SACAR_COMILLAS $strng" if $debug;
    my ($coso_locoloto) = $strng =~ m/^\s*'(.+)'$/g;
    say "coso_locoloto == $coso_locoloto" if $debug;
    #die unless $coso_locoloto;
    return $coso_locoloto;
}

# Agregar tipos de parrafos ? ? ?
sub parrafear {
    my $parrafo_br_r = shift;
    my $parrafo_br = boldear($parrafo_br_r);
    my $parrafo    = '<p>' . $parrafo_br . '</p>' . "\n";
    my $br_html = '<br/>';
    $parrafo =~ s/___BR___/$br_html/g;
    say "Parrafo es == $parrafo" if $debug;
    return $parrafo;
}

sub premailear {
    my $salida_ruby = '';
    unless ( $carpete eq '.' ) {
        $salida_ruby = $carpete . '/' . $salida_archivo;
    }
    my $comm =  'ruby pp.rb' . 
                ' ' . $salida_archivo_carpeta_perl . 
                ' ' . $salida_ruby;
    say `$comm`;
}

sub ayudas {
    pod2usage( -verbose => 2 );
    exit;
}

# Agregado en v2
sub hacer_carpeta_salida {
    my $nombre_carpeta = shift;
    $nombre_carpeta .= "_" . $t_banana;
    die unless ( mkdir $nombre_carpeta );
    return $nombre_carpeta;
}

# Agregado para reemplazar saltos de linea en parrafos.
sub reemplazar_enters {
    my $texto = shift;
    say "texto es $texto" if $debug;
    $texto =~ s/$cifrado_enter/\n/g;
    my $salida = $texto;
    say "salida es $salida" if $debug;
    return $salida;
}
######################################################################
# Agregado para permitir algun control adicional sobre el texto
# en negrita.
######################################################################
sub boldear {
    my $string_in            =  shift;
    my $string_outin         =  $string_in;
    my @gilators_pa_boldear  =  ();
    while ($string_in =~ m/(\*\*[^\*]+\*\*)/g){
        push(@gilators_pa_boldear,$1);    
    }
    my $boldin = '<strong>';
    my $boldin_out = '</strong>';
    foreach my $buscado (@gilators_pa_boldear){
        my ($baobab) = $buscado =~ m/\*\*([^\*]+)\*\*/g;
        my $reemplazo = $boldin . $baobab . $boldin_out; 
        $string_outin =~ s/\Q$buscado/$reemplazo/g;
    }
    say "BOLDEAR $string_outin" if $debug;
    return $string_outin;
}
######################################################################
# Agregado para convertir en enlaces html las direcciones wen 
# y enlaces dentro del texto.
######################################################################
sub linkeame_el_texto {
    my $input             = shift;
    my $rgx_tutti_Outside = '([\[][^\[\]]*[\]][\(][^\(\)]*[\)])';
    my @linkis            = ();
    while ( $input =~ m/$rgx_tutti_Outside/gi ) {
        push( @linkis, $1 );
    }
    my $rgx_tutti_inside        = '[\[]([^\[\]]+)[\]][\(]([^\(\)]+)[\)]';
    my $rgx_solo_URL_corchetes  = '[\[][\]][\(]([^\(\)]+)[\)]';
    my $rgx_solo_URL_parentesis = '[\[]([^\[\]]+)[\]][\(][\)]';
    my $string_out              = $input;

    return $input unless (@linkis);

    foreach my $linkinside (@linkis) {
        my ( $texto_link, $url_link, $sacar );
        if ( $linkinside =~ m/$rgx_solo_URL_corchetes/g ) {
            $texto_link = $1;
            $url_link   = $1;
            $sacar      = '\[' . $1 . '\]\(' . '\)';
        }
        if ( $linkinside =~ m/$rgx_solo_URL_parentesis/g ) {
            $texto_link = $1;
            $url_link   = $1;
            $sacar      = '\[' . '\]\(' . $1. '\)';
        }
        if ( $linkinside =~ m/$rgx_tutti_inside/g ) {
            $texto_link = $1;
            $url_link   = $2;
            $sacar      = '\[' . $texto_link . '\]\(' . $url_link . '\)';
        }
        my $salida_link = '<a href="' . $url_link . '" target="_blank">' . 
                            $texto_link . '</a>';
        $string_out =~ s/$sacar/$salida_link/g;
    }
    say $string_out if $debug;
    return $string_out;
}
######################################################################
# Pods
######################################################################

=pod

=encoding utf8

=head1 Descripcion.

Este programa llena una plantilla con el objeto de hacer un newsletter.

=head1 SYNOPSIS

Este programa llena una plantilla con el objeto de hacer un newsletter.
Las plantillas pueden ser cualquier tipo de archivo que contenga las variables
en los lugares donde el texto va a ser reemplazado.

Las variables son leidas desde un arhcivo de configuracion y deben coincidir en
nombre, seguidas del valor que contienen (por el que van a ser reemplazadas en 
el documento final).

Una vez hecho el reemplazo, se utiliza premailer (mediante el scriptcillo pp.rb 
-en Ruby-) para pasar todo el css inline, remover ids de los divs y los comentarios.

=head2 Forma de uso:

Este programa B<NECESITA> los parametros -c y -t especificando archivos reales.

Opcionalmente se puede usar la opcion -d (sin argumentos), para activar el debugging.

=over

=item * -c [ARCHIVO CONFIGURACION]      OBLIGATORIO! Especifica el archivo con los campos y los valores a utilizar en el reemplazo.

=item * -t [ARCHIVO PLANTILLA]          OBLIGATORIO! Especifica el archivo en donde las variables van a ser reemplazadas.

=item * -h                              Esta ayuda

=back


=head2 Cambios

Se agrego soporte para B<br>.

Utilizar la siguiente notacion : __BR__ y sera reemplazado por la etiqueta HTML 
correspondiente.


Se agrego soporte para B<URLs> y B<negrita>.

Para Urls:
----------------

Escribir con esta sintaxis [un link](pagina.com); se puede omitir el contenido 
entre parentesis o corchetes pero no ambos.

Para bold:
----------------

Utilizar **esta sintaxis**.


B<Si estamos viendo esta ayuda sin pedirla, quiere decir que faltaron alguna de las opciones de arriba.>


~ GsTv ~ 2014,2015... y contando.                            Zaijian.

=cut
