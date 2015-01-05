#!/bin/bash

## Esta opción es para activar o desactivar las copias de respaldo al servidor ftp
respaldoftp="no"

## ----- Variables -----
# Fechas
fecha=`date +%Y-%m-%d`
diasBorraSql="15"
diasBorraSqlGz="30"
diasBorrawwwGz="30"
# Rutas
remoto="/"
remotoDB="[No disponible]"
remotowww="[No disponible]"
localDescDB="$HOME/Backups/Desc/DB"
localDescwww="$HOME/Backups/Desc/Host"
LocalBackupDB="$HOME/Backups/DB"
LocalBackupwww="$HOME/Backups/Host"
localLogs="$HOME/Backups/Logs"
# Datos conexión ssh
sshuser=""
sshpass=""
sshhost=""
# Datos conexión ftp
ftpuser=""
ftppass=""
ftphost=""
# Datos conexión db
dbuser=""
dbpass=""
dbhost=""
dbname=""
# Datos respaldo ftp
respftpuser=""
respftppass=""
respftphost=""
respftpDB=""
respftpwww=""

## ----- Comprobar e instalar paquetes necesarios -----
DEP=(" openssh mariadb expect tar rsync" )
for d in $DEP; do
	[ $( pacman -Qq "$d" 2> /dev/null ) ] && inst+="$d " || ninst+="$d "
done
sudo pacman --noconfirm -Sy $ninst

## Comprobamos si tenemos los directorios para las copias, de lo contrario los crea
if [ ! -x $localDescDB ];then
	mkdir -p $localDescDB
fi
if [ ! -x $localDescwww ];then
	mkdir -p $localDescwww
fi
if [ ! -x $LocalBackupDB ];then
	mkdir -p $LocalBackupDB
fi
if [ ! -x $LocalBackupwww ];then
	mkdir -p $LocalBackupwww
fi
if [ ! -x $localLogs ];then
	mkdir -p $localLogs
fi
	
# Introducimos en el remoto la llave pública ssh si no existe
expect -c "
	log_user 0
	spawn ssh-copy-id ${sshuser}@${sshhost}
	match_max 100000
	expect \"*?assword:*\" { send -- \"$sshpass\r\"}
	expect 100%
	sleep 1
	log_user 1
	exit
"

# Backup de la base de datos
ssh $sshuser@$sshhost "mysqldump -h $dbhost -u $dbuser -p$dbpass -B $dbname" > $localDescDB/$dbname-$fecha.sql

# Comprime la base de datos y copia el fichero a la carpeta pertinente
tar -czf $LocalBackupDB/$dbname-$fecha.sql.tar.gz $localDescDB/$dbname-$fecha.sql

# Borra los archivos DB más antiguos de la fecha especificada
find $localDescDB/ -mtime +$diasBorraSql -exec rm -rf {} \;
find $LocalBackupDB/ -mtime +$diasBorraSqlGz -exec rm -rf {} \;

# Descarga o actualiza carpeta desde host
rsync -avz --delete --progress -e "ssh" --exclude 'Backups' $sshuser@$sshhost:$remoto $localDescwww >> $localLogs/backup-$fecha.log 2>&1

# comprime la carpeta descargada del host
tar -czf $LocalBackupwww/host-$fecha.tar.gz $localDescwww

if [ $respaldoftp = si ]; then
	# Envia las copias comprimidas via ftp a nuestro espacio de respaldo en la nuve
	ftp -inv  $respftphost <<Done-ftp
	user $respftpuser $respftppass
	put $LocalBackupDB/$dbname-$fecha.sql.tar.gz $respftpDB/$dbname-$fecha.sql.tar.gz
	put $LocalBackupwww/host-$fecha.tar.gz $respftpwww/host-$fecha.tar.gz
	bye
Done-ftp
else
	echo "No tienes configurado el respaldo por ftp"
	sleep 5
	clear
fi	
# Borra los archivos host más antiguos de la fecha especificada
find $LocalBackupwww/ -atime +$diasBorrawwwGz -exec rm -rf {} \;