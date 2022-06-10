# This script is executed by crond. Have a look at /etc/cron.d for more information about scheduling

NOW=`date +"%Y-%m-%dT%H-%M-%S"`
echo "Backup job ran at $NOW" >> /var/log/quintus-backup.log

# Setting up variables
MONGO_BACKUP_FILE_NAME="$NOW-mongo-backup.tar.gz"
SQL_BACKUP_FILE_NAME="$NOW-sql-backup.tar.gz"
DB_BACKUP_DIRECTORY="/data/home/msb/db-backup"
MONGO_TMP_DIRECTORY="/tmp/mongo-backup"
MSSQL_TMP_DIRECTORY="/tmp/mssql-backup"
MSSQL_BACKUP_SCRIPT="/tmp/mssql-backup.sh"

#Containers
SQL_CONTAINER="press-sql"
MONGO_CONTAINER="press-mongodb"

# SQL databases
SQL_AUTH_DB="AuthDb"
SQL_DOC_DB="DocumentDb"
SQL_LOG_DB="LoggingDb"
SQL_MASTER_DB="MasterDb"
SQL_PRESS_DB="PressDb"
SQL_USER="sa"
SQL_PASSWORD="Banan1234!"

echo "MONGO_BACKUP_FILE_NAME: " $MONGO_BACKUP_FILE_NAME
echo "SQL_BACKUP_FILE_NAME: " $SQL_BACKUP_FILE_NAME
echo "DB_BACKUP_DIRECTORY: " $DB_BACKUP_DIRECTORY
echo "MONGO_TMP_DIRECTORY: " $MONGO_TMP_DIRECTORY
echo "MSSQL_TMP_DIRECTORY: " $MSSQL_TMP_DIRECTORY
echo "MSSQL_BACKUP_SCRIPT: " $MSSQL_BACKUP_SCRIPT

# Create directories
mkdir -p $DB_BACKUP_DIRECTORY
mkdir -p $MONGO_TMP_DIRECTORY
mkdir -p $MSSQL_TMP_DIRECTORY
echo "Directories created"

# Create MonogDb backups
docker exec -i $MONGO_CONTAINER /usr/bin/mongodump --out $MONGO_TMP_DIRECTORY
echo "MongoDb backups created"

# Copy MongoDb backups localy
docker cp $MONGO_CONTAINER:$MONGO_TMP_DIRECTORY $MONGO_TMP_DIRECTORY
docker exec -i $MONGO_CONTAINER rm -r $MONGO_TMP_DIRECTORY
echo "MongoDb backups copied"

# Compress MongoDb backups
tar -czvf $DB_BACKUP_DIRECTORY/$MONGO_BACKUP_FILE_NAME $MONGO_TMP_DIRECTORY
echo "MongoDb backups compressed"

# Remove MongoDb temp directory
rm -r $MONGO_TMP_DIRECTORY

# Create SQL backup script
rm -f /p/a/t/h $MSSQL_BACKUP_SCRIPT
touch $MSSQL_BACKUP_SCRIPT
echo 'PRINT "Start Backup process...";' >> $MSSQL_BACKUP_SCRIPT
echo "mkdir -p $MSSQL_TMP_DIRECTORY"
echo 'DECLARE @MyFileName varchar(200)' >> $MSSQL_BACKUP_SCRIPT
echo "SELECT @MyFileName=N'"$MSSQL_TMP_DIRECTORY"/Backup_"$SQL_AUTH_DB"' + convert(nvarchar(20),GetDate(),112)+'_'+convert(nvarchar(20),GetDate(),108)+ '.bak'" >> $MSSQL_BACKUP_SCRIPT
echo "BACKUP DATABASE [$SQL_AUTH_DB] TO DISK=@MyFileName" >> $MSSQL_BACKUP_SCRIPT
echo "SELECT @MyFileName=N'"$MSSQL_TMP_DIRECTORY"/Backup_"$SQL_DOC_DB"' + convert(nvarchar(20),GetDate(),112)+'_'+convert(nvarchar(20),GetDate(),108)+ '.bak'" >> $MSSQL_BACKUP_SCRIPT
echo "BACKUP DATABASE [$SQL_DOC_DB] TO DISK=@MyFileName" >> $MSSQL_BACKUP_SCRIPT
echo "SELECT @MyFileName=N'/"$MSSQL_TMP_DIRECTORY"/Backup_"$SQL_LOG_DB"' + convert(nvarchar(20),GetDate(),112)+'_'+convert(nvarchar(20),GetDate(),108)+ '.bak'" >> $MSSQL_BACKUP_SCRIPT
echo "BACKUP DATABASE [$SQL_LOG_DB] TO DISK=@MyFileName" >> $MSSQL_BACKUP_SCRIPT
echo "SELECT @MyFileName=N'"$MSSQL_TMP_DIRECTORY"/Backup_"$SQL_MASTER_DB"' + convert(nvarchar(20),GetDate(),112)+'_'+convert(nvarchar(20),GetDate(),108)+ '.bak'" >> $MSSQL_BACKUP_SCRIPT
echo "BACKUP DATABASE [$SQL_MASTER_DB] TO DISK=@MyFileName" >> $MSSQL_BACKUP_SCRIPT
echo "SELECT @MyFileName=N'"$MSSQL_TMP_DIRECTORY"/Backup_"$SQL_PRESS_DB"' + convert(nvarchar(20),GetDate(),112)+'_'+convert(nvarchar(20),GetDate(),108)+ '.bak'" >> $MSSQL_BACKUP_SCRIPT
echo "BACKUP DATABASE [$SQL_PRESS_DB] TO DISK=@MyFileName" >> $MSSQL_BACKUP_SCRIPT
echo 'PRINT "Finished backup process...";' >> $MSSQL_BACKUP_SCRIPT
echo "MSSQL backup script created"

# Delete SQL backup script from container
docker exec -u 0 -i $SQL_CONTAINER rm $MSSQL_BACKUP_SCRIPT
# Copy new SQL backup script to container
docker cp $MSSQL_BACKUP_SCRIPT $SQL_CONTAINER:$MSSQL_BACKUP_SCRIPT
rm -r $MSSQL_BACKUP_SCRIPT
echo "MSSQL backup script created and copied to the container"

# Run SQL backup script in press-sql container
docker exec -u 0 -i $SQL_CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U $SQL_USER -P $SQL_PASSWORD -i $MSSQL_BACKUP_SCRIPT
echo "MSSQL backup completed in container"

# Copy container backups localy
docker cp $SQL_CONTAINER:$MSSQL_TMP_DIRECTORY /tmp
echo "MSSQL backup files copied localy"

# Delete backup files in container
docker exec -u 0 -i $SQL_CONTAINER rm -r $MSSQL_TMP_DIRECTORY
echo "Deleted local backup files"

# Compress MSSQL backups
tar -czvf $DB_BACKUP_DIRECTORY/$SQL_BACKUP_FILE_NAME $MSSQL_TMP_DIRECTORY
rm -r $MSSQL_TMP_DIRECTORY
echo "MSSQL backups compressed"

# Remove old backup files
find $DB_BACKUP_DIRECTORY -mtime +7 -type f -delete
echo "Removed old backup files"