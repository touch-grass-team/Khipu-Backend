#!/bin/bash

#colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

INSTALLER_DIR=$(pwd)
apt-get update

#install postgresql
IS_PGSQL_INSTALLED=$(dpkg-query -W -f='${Status}\n' postgresql)
if [[ "$IS_PGSQL_INSTALLED" != "install ok installed" ]]
	then
	apt --assume-yes  install postgresql
fi

POSTGRES_STATUS=$(systemctl status postgresql | grep "Active:" | awk '{print $2}')
if [[ "$POSTGRES_STATUS" == "active" ]]
	then
	echo $(ss -tunelp | grep uid:`id -u postgres`)
	echo -e "${GREEN}Postgresql installed and active${NC}"
else
	echo -e "${RED}Postgresql failed to start${NC}"
fi

#give postgres rights to facl
usermod -a -G shadow postgres
setfacl -d -m u:postgres:r /etc/parsec/macdb
setfacl -R -m u:postgres:r /etc/parsec/macdb
setfacl -m u:postgres:rx /etc/parsec/macdb

#configure logwriter
if ! grep -q logwriter /etc/passwd
	then
	useradd -M -s /bin/bash logwriter
	pdpl-user -l 0:0 logwriter
	setfacl -m u:postgres:r /etc/parsec/macdb/$(id -u logwriter)
fi

if ! grep -q logwriter /etc/postgresql/11/main/pg_hba.conf
	then
	echo "local syslog_ng logwriter peer" >> /etc/postgresql/11/main/pg_hba.conf
fi	

#configure logreader
if ! grep -q logreader /etc/passwd 
	then
	useradd -M -s /bin/bash logreader
	pdpl-user -l 0:0 logreader
	setfacl -m u:postgres:r /etc/parsec/macdb/$(id -u logreader)
fi

if ! grep -q logreader /etc/postgresql/11/main/pg_hba.conf
	then
	echo "local syslog_ng logreader peer" >> /etc/postgresql/11/main/pg_hba.conf
fi	

systemctl restart postgresql

#install syslog_ng db
cd ~postgres/
cp $INSTALLER_DIR/scripts/init.sql $(pwd)
su postgres -c "createdb -O postgres -e syslog_ng; \
	psql -U postgres -d syslog_ng -f init.sql;"	
rm init.sql