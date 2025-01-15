#!/bin/bash
#export ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
export ORACLE_HOME=/u01/app/oracle/product/19.3.0/dbhome_1
export PATH=$ORACLE_HOME/bin:$PATH
export NLS_DATE_FORMAT="dd-mm-yy hh24:mi:ss"
export ORACLE_SID={{oracle_sid}}
BASE_PATH=/backups/RMAN/COREP_??
datef=`date '+%d%m%y'`
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
catalog start with '/backups/RMAN/' NOPROMPT;
SET NEWNAME FOR DATABASE TO '+DATA/${ORACLE_SID}/DATAFILE/%b';
restore database VALIDATE;
}
EOF
