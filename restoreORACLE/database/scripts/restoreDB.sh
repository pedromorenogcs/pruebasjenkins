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
rman target / <<EOF
SET DBID 628811412;
RUN {
RESTORE CONTROLFILE FROM  '${FULL_CTL_FILE}';
}
EOF
