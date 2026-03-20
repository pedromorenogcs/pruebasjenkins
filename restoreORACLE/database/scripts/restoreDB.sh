#!/bin/bash
export ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
#export ORACLE_HOME=/u01/app/oracle/product/19.3.0/dbhome_1
export PATH=$ORACLE_HOME/bin:$PATH
export NLS_DATE_FORMAT="dd-mm-yy hh24:mi:ss"
export ORACLE_SID={{oracle_sid}}
BASE_PATH=/backups/RMAN/COREP_??
datef=`date '+%d%m%y'`
FIRST_ARCH="`date '+%Y-%m-%d'` 00:00:00"
EVIDENCE_FILE=/tmp/evidence.txt

#### Logging function
LOGFILE=/tmp/restoreDB.log
MYPID=$$
PROJECT=M2M
PROJECTACTION=RESTOREDR
LOGTITLE="$PROJECT $PROJECTACTION"
function logging_fn() {
  #### LOGGING FORMAT: PROJECT PROJECTACTION EPOCH PID TEXT ####
  echo $LOGTITLE $(date +%s) $MYPID $1 |tee -a $LOGFILE >>/dev/null
}
#### END logging function


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
                echo $LOGTITLE $(date +%s) ERROR $MYPID ${errcode} |tee -a $LOGFILE >>/dev/null
                exit $errcode
                ;;
esac
}
###### END FUNCTION CHECK RETURN CODE ######
rman target / LOG=${LOGFILE} APPEND <<EOF
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
catalog start with '/backups/RMAN/' NOPROMPT;
SET NEWNAME FOR DATABASE TO '+DATA/${ORACLE_SID}/DATAFILE/%b';
restore archivelog from time "to_date('$FIRST_ARCH','yyyy-mm-dd hh24:mi:ss')";
restore database;
switch datafile all;
recover database;
}
exit;
EOF

sqlplus -s /nolog >> ${LOGFILE} <<EOF
connect /as sysdba
set lines 300
set pages 300
set heading off
set verify off
set feedback off
col DATABASE_NAME format a40
alter session set nls_date_format='dd-yy-mm hh24:mi:ss';
create spfile from pfile='/home/oracle/init${ORACLE_SID}.ora';
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

### IF CURRENT DBROLE IS A PHYSICAL STANDBY###
if [ "$DATABASE_ROLE" == "PHYSICAL STANDBY" ]
then
    sqlplus -s /nolog <<EOF
    conn / as sysdba
    set lines 300
    set pages 300
    set heading off
    set verify off
    alter session set nls_date_format='dd-yy-mm hh24:mi:ss';
    spool ${LOGFILE} APPEND
    alter database flashback off;
    alter database activate standby database;
    shutdown immediate;
    startup;
    spool off
    exit
EOF
    fn_err $?
### ELSE, IS A PRIMARY ROLE DATABASE ###
elif [ "$DATABASE_ROLE" == "PRIMARY" ]
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
    spool ${LOGFILE} APPEND
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
spool ${EVIDENCE_FILE}
select database_name, open_mode, RESETLOGS_TIME from v\$database;
spool off
exit
EOF
fn_err $?
logging_fn $(cat ${EVIDENCE_FILE})
cat ${LOGFILE} |grep "Finished restore" |tail -1
cat ${EVIDENCE_FILE}
