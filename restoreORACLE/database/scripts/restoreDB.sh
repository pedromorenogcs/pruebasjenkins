#!/bin/bash
set -x
### CHECK ORACLE_SID as PARAMETER ###
if [ ! -z "$1" ]
  then
    echo "execute: ./Backup_Full.sh [ORACLE_SID]"
    exit 1
fi
#export ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
export ORACLE_HOME=/u01/app/oracle/product/19.3.0/dbhome_1
export PATH=$ORACLE_HOME/bin:$PATH
export NLS_DATE_FORMAT="dd-mm-yy hh24:mi:ss"
export ORACLE_SID={{oracle_sid}}
datef=`date '+%d%m%y'`
BASE_PATH=/backups/RMAN/COREP_??
export CTL_FILE=${BASE_PATH}/${datef}???????-?????????-????????-??
echo $CTL_FILE
FULL_CTL_FILE=`ls $CTL_FILE |tail -1`
echo "--"$FULL_CTL_FILE"---"
echo "File exists: " $?
#exit
###### FUNCTION RETURN CODE ######
fn_err () {
errcode=$1
case $errcode in
        0)
                ;;
        *)
                echo "`date +%d%m%y%H%M%S`: ERROR, EXITING WITH ERROR CODE $errcode"
                exit $errcode
                ;;
esac
}
###### END FUNCTION CHECK RETURN CODE ######
rman target / LOG=/tmp/verlog.log <<EOF
RUN {
startup nomount PFILE='/home/oracle/init${ORACLE_SID}.ora';
SET DBID 628811412;
ALLOCATE CHANNEL ch1 DEVICE TYPE DISK;
ALLOCATE CHANNEL ch2 DEVICE TYPE DISK;
ALLOCATE CHANNEL ch3 DEVICE TYPE DISK;
ALLOCATE CHANNEL ch4 DEVICE TYPE DISK;
ALLOCATE CHANNEL ch5 DEVICE TYPE DISK;
ALLOCATE CHANNEL ch6 DEVICE TYPE DISK;
ALLOCATE CHANNEL ch7 DEVICE TYPE DISK;
ALLOCATE CHANNEL ch8 DEVICE TYPE DISK;
RESTORE CONTROLFILE FROM  '${FULL_CTL_FILE}';
alter database mount;
crosscheck archivelog all;
delete noprompt expired archivelog all;
SET NEWNAME FOR DATABASE TO '+DATA/${ORACLE_SID}/DATAFILE/%b';
restore database;
switch datafile all;
recover database;
}
EOF
tail -10 /tmp/verlog.log

sqlplus -s /nolog > /tmp/renameredo.log<<EOF
whenever oserror exit oscode
whenever sqlerror exit sql.sqlcode
connect /as sysdba
set lines 300
set pages 300
set heading off
set verify off
col DATABASE_NAME format a40
alter session set nls_date_format='dd-yy-mm hh24:mi:ss';
spool /tmp/renameRedo.sql
select 'alter database rename file '''||MEMBER||''' to ''+RECO/${ORACLE_SID}' || SUBSTR(MEMBER,instr(MEMBER,'/',1,2)) || ''';' from v\$logfile;
select 'alter database drop standby logfile group '||group#||';' from v\$logfile where TYPE='STANDBY';
select 'alter database clear logfile group '||GROUP#||';' from v\$logfile;
spool off
@/tmp/renameRedo.sql
EOF

###### CURRENT DBROLE ######
DATABASE_ROLE=`sqlplus -s / "as sysdba" <<EOF
whenever oserror exit oscode
whenever sqlerror exit sql.sqlcode
set pages 0
set head off
set feedback off
select trim(database_role) from v\\$database;
exit
EOF`
###### END CURRENT DBROLE ######
echo ${DATABASE_ROLE}

### IF CURRENT DBROLE IS NOT A PHYSICAL STANDBY###
if [ "$DATABASE_ROLE" == "PHYSICAL STANDBY" ]
then
    sqlplus -s /nolog <<EOF
    whenever oserror exit oscode
    whenever sqlerror exit sql.sqlcode
    conn / as sysdba
    set lines 300
    set pages 300
    set heading off
    set verify off
    alter session set nls_date_format='dd-yy-mm hh24:mi:ss';
    spool /tmp/opendatabase.log
    alter database activate standby database;
    shutdown immediate;
    startup
    spool off
    exit
    EOF
    fn_err $?
### ELSE, IS A PRIMARY ROLE DATABASE ###
elif [ "$DATABASE_ROLE" == "PRIMARY" ]
    sqlplus -s /nolog <<EOF
    whenever oserror exit oscode
    whenever sqlerror exit sql.sqlcode
    conn / as sysdba
    set lines 300
    set pages 300
    set heading off
    set verify off
    alter session set nls_date_format='dd-yy-mm hh24:mi:ss';
    spool /tmp/opendatabase.log
    alter database open resetlogs;
    spool off
    EOF
    fn_err $?
fi
### EVIDENCE ###
sqlplus -s /nolog >>/dev/null <<EOF
whenever oserror exit oscode
whenever sqlerror exit sql.sqlcode
conn / as sysdba
set lines 300
set pages 300
set heading off
set verify off
col DATABASE_NAME format a40
alter session set nls_date_format='dd-yy-mm hh24:mi:ss';
spool /tmp/evicende.txt
select database_name, open_mode, RESETLOGS_TIME from v\\$database;
spool off
exit
EOF
fn_err $?
cat /tmp/verlog.log |grep "Finished restore" |tail -1
cat /tmp/evicende.txt
