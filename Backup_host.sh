#!/bin/bash
clear

## ########## VARIABLES ########## ##

# ---- OBLIGATORIAS QUE TENGAN CONTENIDO ---- #
respaldoftp="no"						# Esta opción es para activar o desactivar las copias de respaldo al servidor ftp "si/no"
remoto="/"								# Nombre del sitio que vamos a hacer las copias. En caso de ser raiz ponemos /
direct=""								# Nombre del directorio que guardará las copias en local. Este se creará en nuestro home
diasBorraSql="15"						# Días que guardará los archivos mysql
diasBorraSqlGz="30"						# Días que guardará los archivos mysql comprimidos
diasBorrawwwGz="30"						# Días que guardará los alchivos del host comprimidos
# Datos conexión ssh
sshuser=""								# Usuario para la conexión ssh
sshpass=""								# Contraseña para la conexión ssh
sshhost=""								# Dirección de conexión ssh de nuestro proveedor
# Datos conexión ftp
ftpuser=""								# Usuario para la conexión ftp
ftppass=""								# Contraseña para la conexión ftp
ftphost=""								# Dirección de conexión ftp de nuestro proveedor
# Datos conexión db
dbuser=""								# Usuario para la conexión mysql
dbpass=""								# Contraseña para la conexión mysql
dbhost=""								# Dirección de conexión mysql de nuestro proveedor
dbname=""								# Nombre de la base de datos

# ---- OPCIONALES ---- #
# Datos respaldo ftp
respftpuser=""							# Usuario para la conexión de respaldo ftp
respftppass=""							# Contraseña para la conexión de respaldo ftp
respftphost=""							# Dirección de conexión respaldo ftp de nuestro proveedor
respftpDB=""							# Ruta de respaldo en el ftp para base de datos
respftpwww=""							# Ruta de respaldo en el ftp archivos del host

# --------- ¡¡ NO MODIFICAR --- NO MODIFICAR !! ---------
fecha=`date +%Y-%m-%d`
dire="$HOME/Backups"
localLogs="$dire/Logs"
dir=(" $dire/${direct}_Desc/DB $dire/${direct}_Desc/www $dire/$direct/DB $dire/$direct/www $dire/Logs" )
localLogs="$dire/Logs"
dep=(" openssh mariadb expect tar rsync" )
localDescDB="$dire/${direct}_Desc/DB"
localDescwww="$dire/${direct}_Desc/www"
LocalBackupDB="$dire/$direct/DB"
LocalBackupwww="$dire/$direct/www"

## ----- Comprobamos que las variables obligatorias estén completas ----- ##
for var in respaldoftp direct remoto sshuser sshpass sshhost ftpuser ftppass ftphost dbuser dbpass dbhost dbname; do
	if [ -z ${!var} ] ; then
		echo "Para poder ejecutar el script debes rellenar las variables obligatorias"
		exit
	fi
done

## ----- Comprobar e instalar paquetes necesarios -----
for d in $dep; do
	[ $( pacman -Qq "$d" 2> /dev/null ) ] && inst+="$d " || ninst+="$d "
done
sudo pacman --noconfirm -Sy $ninst

## Comprobamos si tenemos los directorios para las copias, de lo contrario los crea
for f in $dir; do
	[ -d $dir 2> /dev/null ] && direc+="$f " || ndirec+="$f "
done
mkdir -p $ndirec
	
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