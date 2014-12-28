#!/bin/bash

## ----- Variables -----
# Fechas
fecha=`date +%Y-%m-%d`
diasBorraSql="15"
diasBorraSqlGz="30"
diasBorraHost="15"
diasBorraHostGz="30"
# Rutas
remoto=""
remotoDB="Backups/DB"
remotoHost="Backups/Host"
localDescDB="$HOME/Backups/Desc/DB"
localDescHost="$HOME/Backups/Desc/Host"
LocalBackupDB="$HOME/Backups/DB"
LocalBackupHost="$HOME/Backups/Host"
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
rsync -avz --delete --progress -e "ssh" $sshuser@$sshhost:$remoto $localDescHost >> $localLogs/backup$fecha.log 2>&1

# comprime la carpeta descargada del host
tar -czf $LocalBackupHost/host$fecha.tar.gz $localDescHost

# Borra los archivos host más antiguos de la fecha especificada
#find $localDescHost/ -mtime +$diasBorraHost -exec rm -rf {} \;
find $LocalBackupHost/ -mtime +$diasBorraHostGz -exec rm -rf {} \;