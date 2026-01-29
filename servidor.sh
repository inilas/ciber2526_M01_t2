#/bin/bash
#servidor
VERSION_CURRENT="0.7"

PORT="9999"
IP_CLIENT="localhost"
SERVER_DIR="server"

clear

mkdir -p $SERVER_DIR

echo "Servidor de RECTP v$VERSION_CURRENT"

IP_LOCAL=`ip -4 addr | grep "scope global" | awk '{print $2}' | cut -d "/" -f 1`

echo "IP Local: $IP_LOCAL"

echo "0. LISTEN. HEADER"

DATA=`nc -l -p $PORT`

echo "3.1. TEST. Datos"

HEADER=`echo $DATA | cut -d " " -f 1`

if [ "$HEADER" != "RECTP" ]
then
	echo "ERROR 1: Cabecera errónea"

	sleep 1
	echo "HEADER_KO" | nc $IP_CLIENT -q 0 $PORT

	exit 1
fi

VERSION=`echo $DATA | cut -d " " -f 2`

if [ "$VERSION" != "$VERSION_CURRENT" ]
then
	echo "ERROR 2: Versión errónea"

	sleep 1
	echo "HEADER_KO" | nc $IP_CLIENT -q 0 $PORT

	exit 2
fi

IP_CLIENT=`echo $DATA | cut -d " " -f 3`

if [ "$IP_CLIENT" == "" ]
then
	echo "Error 4: IP de cliente mal formada ($IP_CLIENT)"

	exit 4
fi


IP_CLIENT_HASH=`echo $DATA | cut -d " " -f 4`


IP_CLIENT_HASH_TEST=`echo "$IP_CLIENT" | md5sum | cut -d " " -f 1`




if [ "$IP_CLIENT_HASH_TEST" != "$IP_CLIENT_HASH" ]
then
	echo "Error 4h: IP de cliente malformada (Hash erroneo)"
	exit 4
fi


echo "8.1 TEST"


echo "3.2. RESPONSE. Enviando HEADER_OK"

sleep 1
echo "HEADER_OK" | nc $IP_CLIENT -q 0 $PORT

echo "4. LISTEN. Nombre de archivo"

DATA=`nc -l -p $PORT`

echo "8. FILE NAME"

echo "8.1 TEST"

echo -e "\nName file:$DATA"


FILE_NAME_PREFIX=`echo $DATA | cut -d " " -f 1`

if [ "$FILE_NAME_PREFIX" != "FILE_NAME" ]
then
	echo "Error 3: Prefijo FILE_NAME incorrecto ($FILE_NAME_PREFIX)"

	sleep 1
	echo "FILE_NAME_KO" | nc $IP_CLIENT -q 0 $PORT

	exit 3
fi

FILE_NAME=`echo $DATA | cut -d " " -f 2`


FILE_NAME_HASH=`echo $DATA | cut -d " " -f 3`


FILE_NAME_HASH_COMPROBATION=`echo "$FILE_NAME" | md5sum | cut -d " " -f 1`


echo -e "\nFile name hash: $FILE_NAME_HASH"

if [ "$FILE_NAME_HASH" != "$FILE_NAME_HASH_COMPROBATION" ]
then
	echo "Error 3h: El hash del nombre no es correcto"
	exit 3
fi


echo -e "File Name: $FILE_NAME\n"

echo "8.2 RESPONSE FILE_NAME_OK"

sleep 1
echo "FILE_NAME_OK" | nc $IP_CLIENT -q 0 $PORT

echo "9. LISTEN FILE DATA"

echo "9.2 STORE FILE DATA"

nc -l -p $PORT>$SERVER_DIR/$FILE_NAME

sleep 1

DATA_HASH_RECIVED=`nc -l -p $PORT`

DATA_HASH=`cat "$SERVER_DIR/$FILE_NAME" | md5sum | cut -d " " -f 1`
echo "$DATA_HASH"

echo "$DATA_HASH_RECIVED"

if [ "$DATA_HASH_RECIVED" != "$DATA_HASH" ]
then
	echo "FILE_DATA_KO" | nc $IP_CLIENT -q 0 $PORT
	exit 3
fi





echo "14. SEND. FILE_DATA_OK"

sleep 1
echo "FILE_DATA_OK" | nc $IP_CLIENT -q 0 $PORT

echo "Fin de comunicación"

aplay $SERVER_DIR/$FILE_NAME

exit 0
