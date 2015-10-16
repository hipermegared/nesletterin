#!/bin/bash
######################################################################
# Ekeko comprobador.
######################################################################
[ ! $1 ] && echo "Falta el primer parametro: la plantilla." && exit 1
[ ! $2 ] && echo "Falta el segundo parametro: el archivo de contenido." && exit 1

[ $1 ] && PLANTILLA="$1"
[ $2 ] && CONTENIDO="$2"

echo '--------------------------------------------------'
echo 'Chequear variables del contenido en la plantilla.'
echo '--------------------------------------------------'

for i in $( perl -E '/([^=]+)\s*=/gi and say $1 foreach(<>)' $CONTENIDO ); do
    [ "$i" == "NEWSLETTER_DIR" ] && continue # Saltearse esta variable.
    grep $i $PLANTILLA &>/dev/null  && echo "ok -- $i" || echo ':( '"-- $i <---- NO ESTA EN LA PLANTILLA"; 
done

echo '--------------------------------------------------'
echo 'Chequear variables de la plantilla en el contenido.'
echo '--------------------------------------------------'

for i in $( perl -E '/\{-----\$(\w+)-----\}/gi and say $1 foreach(<>)' $PLANTILLA ); do
    grep $i $CONTENIDO &>/dev/null && echo "ok -- $i" || echo ':( '"-- $i <---- NO ESTA EN EL CONTENIDO"; 
done

echo ''
echo 'GUARDA:' 
echo 'puede estar comentado en el html y dar falsos positivos.'
exit 0;
