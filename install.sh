#!/bin/bash

#colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

INSTALLER_DIR=$(pwd)
PACKAGES=$INSTALLER_DIR/install_src/packages

apt-get update
apt-get --assume-yes install $(cat $PACKAGES)

POSTGRES_STATUS=$(systemctl status postgresql | grep "Active:" | awk '{print $2}')
if [[ "$POSTGRES_STATUS" == "active" ]]
	then
	echo $(ss -tunelp | grep uid:`id -u postgres`)
	echo -e "${GREEN}Postgresql installed and active${NC}"
else
	echo -e "${RED}Postgresql failed to start${NC}"
fi

#configure syslog-ng
SYSLOG_CONF_DIR=/etc/syslog-ng/conf.d
cp -f  $INSTALLER_DIR/install_src/mod-khipu-log-montior.conf $SYSLOG_CONF_DIR

#create and start systemd-service
#SERVER_BIN_DIR=/opt/khipu/backend
#mkdir -p $SERVER_BIN_DIR 2>/dev/null
#source ./build.sh	
#cp -f $INSTALLER_DIR/build/khipu $SERVER_BIN_DIR
#rm -rf build
#cp -f  $INSTALLER_DIR/install_src/khipu.service /etc/systemd/system
#systemctl enable khipu
#systemctl start khipu
systemctl restart syslog-ng

#give postgres rights to facl
usermod -a -G shadow postgres
setfacl -d -m u:postgres:r /etc/parsec/macdb
setfacl -R -m u:postgres:r /etc/parsec/macdb
setfacl -m u:postgres:rx /etc/parsec/macdb

#configure log_writer
if ! grep -q log_writer /etc/passwd
	then
	useradd -M -s /bin/bash log_writer
	pdpl-user -l 0:3 log_writer
	setfacl -m u:postgres:r /etc/parsec/macdb/$(id -u log_writer)
fi

if ! grep -q log_writer /etc/postgresql/11/main/pg_hba.conf
	then
	echo "local syslog_ng log_writer peer" >> /etc/postgresql/11/main/pg_hba.conf
fi	

#configure log_reader
if ! grep -q log_reader /etc/passwd 
	then
	useradd -M -s /bin/bash log_reader
	pdpl-user -l 0:3 log_reader
	setfacl -m u:postgres:r /etc/parsec/macdb/$(id -u log_reader)
fi

if ! grep -q log_reader /etc/postgresql/11/main/pg_hba.conf
	then
	echo "local syslog_ng log_reader peer" >> /etc/postgresql/11/main/pg_hba.conf
fi	

systemctl restart postgresql

#install syslog_ng db
cd ~postgres/
cp $(find $INSTALLER_DIR -name init.sql) $(pwd)
su postgres -c "createdb -O postgres -e syslog_ng; \
	psql -U postgres -d syslog_ng -f init.sql; \
	psql -c \"alter user postgres with password 'postgres'\""	
rm init.sql
cd $INSTALLER_DIR
