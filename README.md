## BACKUP_HOST

* **Backup_host** es un script escrito en bash que se encarga de hacer copias de seguridad de nuestro host remoto y la base de datos.
Antes de utilizarlo, en el inicio del script encontramos unas variables que debemos rellenar con nuestros datos para que sea funcional.
También tenemos que crear unas carpetas en nuestra home para alojar las copias.

- /home/Backups
- /home/Backups/DB
- /home/Backups/Host
- /home/Backups/Logs
- /home/Backups/Desc
- /home/Backups/Desc/DB
- /home/Backups/Desc/Host

En breve actualizaré el script para que las cree automáticamente en caso de no tenerlas creadas.

También es necesario tener instalados los paquetes **expect, openssh, tar, rsync** y **mariadb**. En breve estos paquetes también se instalarán automáticamente en caso de no tenerlos.

