#!/bin/bash
### Main variable ###
source ./user.var
DATE=$(date +%d-%m-%Y)
LOG="$LOG_DIR/$DATE.log"
ECHO="$(which echo) -e"
TAR="$(which tar) -czf"
MYSQLDUMP="$(which mysqldump) -h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER -p$MYSQL_PASS"
PGDUMP="$(which pg_dump) -h $PG_HOST -U $PG_USER -F -c -f"
MAIL=$(which mail)
###
mkdir -p $LOG_DIR
$ECHO "start backups $DATE $(date +%T)" > $LOG
###
send_mail () {
    for EMAIL in $MAIL_LIST; do
        cat $LOG | $MAIL -s "Backups report fo $DATE" $EMAIL
    done
}
dump_files () {
    FILE_DIR="$BACKDIR/files"
    mkdir -p $FILE_DIR
    for LINE in $FILE_LIST; do
        NAME=$( echo $LINE | cut -d':' -f1)
        DIR=$( echo $LINE | cut -d':' -f2)
        $TAR $FILE_DIR/$DATE-$NAME.tar.gz 2>>$LOG\
            && $ECHO "create archive copy $NAME OK in $(date +%T)\n-----" >> $LOG\
            || $ECHO "create archive copy $NAME ALARM in $(date +%T)\n-----" >> $LOG
    done
}
dump_mysql () {
    MYSQL_DIR="$BACKDIR/mysql"
    mkdir -p $MYSQL_DIR
    for DB in $MYSQL_DB_LIST; do
        $MYSQLDUMP $DB | gzip > $MYSQL_DIR/$DATE-$DB.sql.gz 2>>$LOG\
            && $ECHO "create mysql dump $DB OK in $(date +%T)\n-----" >> $LOG\
            || $ECHO "create mysql dump $DB ALARM in $(date +%T)\n-----" >> $LOG
    done
}
dump_psql () {
    PSQL_DIR="$BACKUPDIR/postgres"
    mkdir -p $PSQL_DIR
    for DB in $PG_DB_LIST; do
        $PGDUMP $PSQL_DIR/$DATE-$DB.tar.gz $DB 2>>$LOG\
            && $ECHO "create psql dump $DB OK in $(date +%T)\n-----" >> $LOG\
            || $ECHO "create psql dump $DB ALARM in $(date +%T)\n-----" >> $LOG
    done
}
delete_old () {
    DIR_LIST=$(ls -d $BACKDIR/* | grep -v logs)
    for DIR in $DIR_LIST; do
        find $DIR -type f ! -name "$DAY_MOUNTH*" -mtime +$LIFE_TIME -exec '{}' \; 2>>$LOG\
            && $ECHO "delete old day backups in $DIR OK $(date +%T)\n-----" >> $LOG\
            || $ECHO "delete old day backups in $DIR ALARM $(date +%T)\n-----" >> $LOG
        find $DIR -type f -name "$DAY_MOUNTH*" -mtime +$LIFE_MOUNTH -exec '{}' \; 2>>$LOG\
            && $ECHO "delete old mounth backups in $DIR OK $(date +%T)\n-----" >> $LOG\
            || $ECHO "delete old mounth backups in $DIR ALARM $(date +%T)\n-----" >> $LOG
    done
}
