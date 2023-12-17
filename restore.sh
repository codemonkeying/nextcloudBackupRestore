#!/bin/bash
NCVERSIONSPACE=$(sudo -u www-data php /var/www/html/nextcloud/occ status --version)
NCVERSION=$(echo -n "${NCVERSIONSPACE//[[:space:]]/}")
HOSTNAME=$(cat /etc/hostname)

BACKUPCURRENT(){
echo "enter password for nextcloud database"
sudo mysqldump -u nextcloud -p nextcloud > /home/user/backups/nextcloudb.sql && echo 'nextcloud database dumped successfully'
sudo cp /var/www/html/nextcloud/config/config.php /home/user/backups/ && echo 'nextcloud config.php coppied successfully'
echo 'Backing up nextcloud apps...'
sudo cp -r /var/www/html/nextcloud/apps /home/user/backups/ && echo 'nextcloud apps coppied successfully'
cd /home/user/backups/
echo 'archiving backed up data'
sudo tar -cf "$(date '+%Y-%m-%d_%H%M')-${NCVERSION}-$(HOSTNAME).BU.old.tar" nextcloudb.sql config.php apps && echo 'archiving successful'
mv *BU.old.DebianNC.tar /home/user/
echo 'cleaning up'
sudo rm -R /home/user/backups/config.php /home/user/backups/apps /home/user/backups/nextcloudb.sql && echo 'cleanup successful'
echo 'backup can be found at /home/user/backups/date_time-$(NCVERSION)-$(HOSTNAME).BU.old.tar'
}

RESTOREAUTOBACKUP(){
echo 'extracting latest auto backup...'
cd /home/user/backups/auto
tar -xf "$(ls -1 /home/user/backups/auto/*BU.tar | sort -t . -k2rn | head -1)"
echo 'enter password for nextcloud database:'
sudo mysql -u nextcloud -p nextcloud < nextcloudb.sql && echo 'database restored successfully'
sudo cp -R /home/user/backups/auto/config.php /var/www/html/nextcloud/config/ && echo 'config.php restored successfully'
sudo cp -R /home/user/backups/auto/apps /var/www/html/nextcloud/ && echo 'nextcloud apps restored successfully'
sudo chown -R www-data:www-data /var/www/html/nextcloud/* && echo 'nextcloud ownership restored successfully'
sudo chmod 640 /var/www/html/nextcloud/config/config.php && echo 'config.php permissions restored successfully'
echo 'cleaning up'
sudo rm -R /home/user/backups/auto/config.php /home/user/backups/auto/apps /home/user/backups/auto/nextcloudb.sql
echo 'done'
}

RESTOREMANUALBACKUP(){
echo 'extracting latest manual backup...'
cd /home/user/backups/manual
tar -xf "$(ls -1 /home/user/backups/manual/*BU.tar | sort -t . -k2rn | head -1)"
echo 'enter password for nextcloud database:'
sudo mysql -u nextcloud -p nextcloud < nextcloudb.sql && echo 'database restored successfully'
sudo cp -R /home/user/backups/manual/config.php /var/www/html/nextcloud/config/ && echo 'config.php restored successfully'
sudo cp -R /home/user/backups/manual/apps /var/www/html/nextcloud/ && echo 'nextcloud apps restored successfully' 
sudo chown -R www-data:www-data /var/www/html/nextcloud/* && echo 'nextcloud ownership restored successfully'
sudo chmod 640 /var/www/html/nextcloud/config/config.php && echo 'config.php permissions restored successfully'
echo 'cleaning up'
sudo rm -R /home/user/backups/manual/config.php /home/user/backups/manual/apps /home/user/backups/manual/nextcloudb.sql
echo 'done'
}

RESTORECUSTOMBACKUP(){
read -p "type full path to file (e.g. /home/user/BU.tar) and press enter: " PATH
echo 'extracting backup at $PATH...'
cd $PATH/..
tar -xf $PATH
echo 'enter password for nextcloud database:'
sudo mysql -u nextcloud -p nextcloud < nextcloudb.sql && echo 'database restored successfully'
sudo cp -R config.php /var/www/html/nextcloud/config/ && echo 'config.php restored successfully'
sudo cp -R apps /var/www/html/nextcloud/ && echo 'nextcloud apps restored successfully'
sudo chown -R www-data:www-data /var/www/html/nextcloud/* && echo 'nextcloud ownership restored successfully'
sudo chmod 640 /var/www/html/nextcloud/config/config.php && echo 'config.php permissions restored successfully'
echo 'cleaning up'
sudo rm -R config.php apps nextcloudb.sql
echo 'done'
}

RESTOREOLD(){
echo 'extracting latest old backup...'
cd /home/user/backups/
tar -xf "$(ls -1 /home/user/backups/*BU.old.tar | sort -t . -k2rn | head -1)"
echo 'enter password for nextcloud database:'
sudo mysql -u nextcloud -p nextcloud < nextcloudb.sql && echo 'database restored successfully'
sudo cp -R /home/user/backups/config.php /var/www/html/nextcloud/config/ && echo 'config.php restored successfully'
sudo cp -R /home/user/backups/apps /var/www/html/nextcloud/ && echo 'nextcloud apps restored successfully' 
sudo chown -R www-data:www-data /var/www/html/nextcloud/* && echo 'nextcloud ownership restored successfully'
sudo chmod 640 /var/www/html/nextcloud/config/config.php && echo 'config.php permissions restored successfully'
echo 'cleaning up'
sudo rm -R /home/user/backups/config.php /home/user/backups/apps /home/user/backups/nextcloudb.sql
echo 'done'
}

FIXINSTALLATION(){
read -p "update nextcloud apps (y/n)?" UPNCAPP
case "$UPNCAPP" in [yY]*) sudo -u www-data php /var/www/html/nextcloud/occ app:update --all ;; *) ;; esac

read -p "update nextcloud (y/n)?" UPNC
case "$UPNC" in [yY]*) sudo -u www-data php /var/www/html/nextcloud/occ upgrade && sudo -u www-data php /var/www/html/nextcloud/updater/updater.phar ;; *) ;; esac

read -p "scan nextcloud files for changes(y/n)?" SCAN
case "$SCAN" in [yY]*) sudo -u www-data php /var/www/html/nextcloud/occ files:scan --all ;; *) ;; esac

read -p "run occ maintenance:repair (y/n)? " REPAIR
case "$REPAIR" in [yY]*) sudo -u www-data php /var/www/html/nextcloud/occ maintenance:repair ;; *) ;; esac

read -p "update the host operating system (y/n)? " UPDATEYN
case "$UPDATEYN" in [yY]*) /home/user/.scripts/up.sh ;; *) echo "Skipping UPDATE." ;; esac

read -p "reboot now(y/n)?" REBOOT
case "$REBOOT" in [yY]*) sudo reboot ;; *) ;; esac
}

RESTORE(){
read -p "would you like to create a backup of the current nextcloud instance(y/n)? " CURRENT
case "$CURRENT" in [yY]*) BACKUPCURRENT ;; *) echo "Skipping Backup of current system." ;; esac

read -p "restore from (auto/manual/custom)? " CHOICE

if [ $CHOICE = 'auto' ]; then
        RESTOREAUTOBACKUP
else

if [ $CHOICE = 'manual' ]; then
        RESTOREMANUALBACKUP
else

if [ $CHOICE = 'custom' ]; then
        RESTORECUSTOMBACKUP

else
echo "skipping restore"
fi
fi
fi
}

EXIT(){
exit
}


#main
echo 'Welcome, it appears you wish to restore a backup... good luck!'

echo 'if you used this program to restore a backup and were unsuccessfull, you can restore the backup of the old system using this program now (provided you selected that option previously)'
read -p "would you like to restore a BU.old.tar after a failed restore(y/n)? " IFFAILED
case "$IFFAILED" in [yY]*) RESTOREOLD ;; *) echo "old restore skipped, beginning standard restore" && RESTORE ;; esac

read -p "would you like to fix the system to correct version mismatch(y/n)? " FIXYN
case "$FIXYN" in [yY]*) FIXINSTALLATION ;; *) echo "Skipping fix." ;; esac
/home/user/.scripts/configRestore.sh
echo "actions complete, exiting..."
