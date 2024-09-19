export ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
export PATH=$ORACLE_HOME/bin:$PATH
export ORACLE_SID={{oracle_sid}}
export ORACLE_SID=COREP_DR
echo $ORACLE_SID
datef=`date '+%d%m%y'`
BASE_PATH=/backups/RMAN/COREP_??
export CTL_FILE=${BASE_PATH}/${datef}???????-?????????-????????-??
echo $CTL_FILE
FULL_CTL_FILE=`ls $CTL_FILE`
echo "--"$FULL_CTL_FILE"---"
echo "File exists: " $?
#exit
rman target / LOG=/tmp/verlog.log <<EOF
RUN {
shutdown abort;
startup nomount PFILE='/home/oracle/initCOREP_DR.ora';
SET DBID 628811412;
ALLOCATE CHANNEL ch1 DEVICE TYPE DISK;
ALLOCATE CHANNEL ch2 DEVICE TYPE DISK;
RESTORE CONTROLFILE FROM  '${FULL_CTL_FILE}';
alter database mount;
restore datafile 1 preview;
}
EOF
tail -10 /tmp/verlog.log
