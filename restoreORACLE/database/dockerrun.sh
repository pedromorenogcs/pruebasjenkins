sudo ./buildContainerImage.sh -e -v 19.3.0
sudo docker run --name orclcontainer19c \
-p 1521:1521 -p 5500:5500 -p 2448:2448 \
--ulimit nofile=1024:65536 --ulimit nproc=2047:16384 --ulimit stack=10485760:33554432 --ulimit memlock=3221225472 \
-e ORACLE_SID=orcl \
-e ORACLE_PDB=mipdb \
-e ORACLE_PWD="or2*24C*leF3do44_d" \
-e INIT_SGA_SIZE=800 \
-e INIT_PGA_SIZE=100 \
-e INIT_CPU_COUNT=2 \
-e INIT_PROCESSES=250 \
-e ORACLE_EDITION=enterprise \
-e ORACLE_CHARACTERSET=AL32UTF8 \
-e ENABLE_ARCHIVELOG=false \
-e ENABLE_FORCE_LOGGING=false \
-e ENABLE_TCPS=false \
-v /opt/oracle/oradata \
oracle/database:19.3.0-ee
