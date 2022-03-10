#####################################################
#            Características del Script             #
#####################################################
#
# NOMBRE: "install_zabbix.sh"
#
# VERSIÓN DE PAQUETES UTILIZADOS:
#
# 1. zabbix-release-5.0-1.el7.noarch.rpm
# 2. 5.5.68-MariaDB
# 3. Apache/2.4.6
# 4. PHP 7.2.34
# 5. grafana-7.3.4-1.x86_64
#
#####################################################

#/usr/bin/bash

if [ "$#" -ne 1 ]; then
        echo "Usage:"
        echo " $0 [options]"
        echo
        echo "Options:"
        echo "  --standalone    (Zabbix only)"
        echo "  --default       (Zabbix + MariaDB + Grafana)"
        echo "  --mariadb       (MariaDB Data Base only)"
        echo "  --grafana       (Grafana Server only)"
        echo

        exit -1
else
        case $1 in
                --mariadb) export OP="MaRiADB" ;;
                  --mysql) export OP="MySqL" ;;
             --standalone) export OP="Standalone" ;;
                --default) export OP="Default" ;;
                --grafana) export OP="Grafana" ;;
                        *) echo; echo "ERROR: Option not found...!"
                           exit -1 ;;
        esac

fi


###################################
#        Pre-requisito WGET       #
###################################
InStALl_WGET ()
{
yum install wget -y
}


###################################
#    Instalacion Base de Datos    #
###################################
InStALl_DB ()
{
if [ $1 = "MaRiADB" ]; then
        MaRiADB

        systemctl stop zabbix-server
        systemctl stop mariadb
        systemctl start mariadb
        systemctl start zabbix-server
fi

if [ $1 = "MySqL" ]; then
        MySqL

        systemctl stop zabbix-server
        systemctl stop mysql
        systemctl start mysql
        systemctl start zabbix-server
fi

###################################
#    Ejecutar armado de schema    #
###################################

DAY=$(date "+%H:%M:%S")

echo "$DAY : EJECUTANDO ARMADO DE SCHEMA..."
echo

if [ $1 = "MaRiADB" ]; then
        echo "THE SCHEMA PASSWORD IS :  z4bb1xDBp4ss"
        PASSWORD=z4bb1xDBp4ss
else
        echo "THE SCHEMA PASSWORD IS :  z4bb1xDBp4ss"
        PASSWORD=z4bb1xDBp4ss
fi
 sleep 1

cd /usr/share/doc/zabbix-server-mysql*/
echo

zcat create.sql.gz | mysql -uzabbix -p"$PASSWORD" zabbix

echo "$DAY : INSTALACION DE ($1)..."
echo "."
echo
echo "Completed...!"
echo
}


########################################
#  Optimizando MySQL/MariaDB database  #
########################################
OpTiMiCe ()
{
DAY=$(date "+%H:%M:%S")

echo "$DAY : OPTIMIZANDO ($1 Database)..."
echo "$DAY : CONFIGURANDO ($1)..."
echo "$DAY : OPTIMIZANDO VALORES DE (/etc/my.cnf)..."
echo "$DAY : ..................................................................................................................................................."
 sleep 1

cp -p /etc/my.cnf /etc/my.cnf.orig

>/etc/my.cnf.temp

cat /etc/my.cnf | while read LINE
do
        PARAMETERS="[mysqld]"

        echo "$LINE" >> /etc/my.cnf.temp

        for i in $PARAMETERS
        do
                COUNTLINE=$(echo "$LINE" | grep "$i]" | wc -l | awk '{print $1}')

                if [ "$COUNTLINE" -ne 1 ]; then

                        STATUS="NOT-MATCH"
                else
                             case "$i" in
                                     "[mysqld]") echo "max_connections = 404 " >> /etc/my.cnf.temp
                                                 CHK=1 ;;

                                              *) echo "ERROR encontrado en parameter...!"
                                                 exit -1 ;;

                             esac
                fi
        done
done

# Renombrando archivo de config.

mv /etc/my.cnf.temp /etc/my.cnf
chown mysql:mysql /etc/my.cnf
}


###################################
#      Base de datos: (local)     #
###################################
MaRiADB ()
{
# 1. Instalar MariaDB
# 2. Crear base de datos.
# 3. Crear usuario.

DAY=$(date "+%H:%M:%S")

echo
echo "$DAY : INSTALANDO BASE DE DATOS (MariaDB)..."
echo

yum install -y mariadb-server

echo
echo "$DAY : INICIANDO EL SERVIVIO DE BASE DE DATOS..."

systemctl start mariadb
systemctl enable mariadb

# Estableciendo permisos.

chown mysql:mysql /etc/my.cnf
chmod 644 /etc/my.cnf

echo
echo "$DAY : ESTABLECIENDO LA ROOT PASSWORD DB..."

mysql -uroot -sN <<+
create database zabbix character set utf8 collate utf8_bin;
create user zabbix@'localhost' identified by 'z4bb1xDBp4ss';
grant all privileges on zabbix.* to zabbix@'localhost';
flush privileges;
quit
+

sleep 1
OpTiMiCe MariaDB
}

###################################
#      Base de datos: (local)     #
###################################
MySqL ()
{
# 1. Instalar MySQL.
# 2. Crear base de datos.
# 3. Crear usuario.

DAY=$(date "+%H:%M:%S")

echo "$DAY : INSTALANDO BASE DE DATOS (MySQL)..."
echo

yum install zabbix-server-mysql

echo "$DAY : INICIANDO EL SERVIVIO DE BASE DE DATOS..."

systemctl restart mysql

echo "$DAY : ESTABLECIENDO LA ROOT PASSWORD DB..."

mysql -uroot -sN <<+
create database zabbix character set utf8 collate utf8_bin;
create user zabbix@'localhost' identified by '123456';
grant all privileges on zabbix.* to zabbix@'localhost';
flush privileges;
quit
+

sleep 1
OpTiMiCe MySQL
}

###################################
#         Grafana Server          #
###################################
InStAlL_GrAf ()
{
if [ $1 = "Grafana" ]; then
        GrAfAnA
        echo
fi
}


###################################
#        FINISH INSTALLATION      #
###################################
FiNiSh ()
{
if [ $1 = "Default" ]; then
        echo "$DAY : INSTALACION DE ZABBIX"
        echo "."
        echo "."
        echo "."
        echo
        echo "Completed...!"

        IP=$(ip a | grep inet | grep -v inet6 | tail -1 | awk 'BEGIN {FS="/"}{print $1}' | awk 'BEGIN {FS="inet"}{print $2}' | sed "s/ //g")

        echo
        echo "***  Puede ingresar a http://$IP/zabbix  ***"
        echo
        echo
fi

if [ $1 = "Standalone" ]; then
        echo "$DAY : INSTALACION DE ZABBIX"
        echo "."
        echo "."
        echo "."
        echo
        echo "Completed...!"
        echo
        echo "***  ES NECESARIO INSTALAR UNA BASE DE DATOS !!!  ***"
        echo
fi
}


###################################
#       PASSWORD ( SCHEMA )       #
###################################
ScHeMa ()
{
echo
echo "THE SCHEMA PASSWORD FOR ( DB ) ZABBIX IS :  z4bb1xDBp4ss"
echo
}


###################################
#        INSTALL ( Types )        #
###################################
InStAlL ()
{
if [ $1 = "Default" ]; then
        ZaBBiX
        InStALl_DB "MaRiADB"
        FiNiSh $1
        InStAlL_GrAf "Grafana"
        ScHeMa
fi

if [ $1 = "Standalone" ]; then
        ZaBBiX
        FiNiSh $1
fi

if [ $1 = "MaRiADB" ]; then
        InStALl_DB $1
fi

if [ $1 = "Grafana" ]; then
        InStAlL_GrAf $1
fi
}


########################################
#    Instalando servidor de Grafana    #
########################################
GrAfAnA ()
{
DAY=$(date "+%H:%M:%S")

echo "$DAY : CONFIGURANDO ARCHIVO DE REPOSITORIO (grafana.repo)..."
echo "$DAY : ..................................................................................................................................................."
 sleep 1

>/etc/yum.repos.d/grafana.repo

echo "[grafana]" >> /etc/yum.repos.d/grafana.repo
echo "name=grafana" >> /etc/yum.repos.d/grafana.repo
echo "baseurl=https://packages.grafana.com/oss/rpm" >> /etc/yum.repos.d/grafana.repo
echo "repo_gpgcheck=1" >> /etc/yum.repos.d/grafana.repo
echo "enabled=1" >> /etc/yum.repos.d/grafana.repo
echo "gpgcheck=1" >> /etc/yum.repos.d/grafana.repo
echo "gpgkey=https://packages.grafana.com/gpg.key" >> /etc/yum.repos.d/grafana.repo
echo "sslverify=1" >> /etc/yum.repos.d/grafana.repo
echo "sslcacert=/etc/pki/tls/certs/ca-bundle.crt" >> /etc/yum.repos.d/grafana.repo

echo "$DAY : INSTALANDO (Grafana)..."
echo
yum install -y initscripts urw-fonts
echo
yum install -y grafana
echo

echo "$DAY : ESTABLECIENDO REGLAS DE FIREWALL..."

sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config
echo

firewall-cmd --zone=public --add-port=3000/tcp --permanent
firewall-cmd --reload
echo

echo "$DAY : INSTALANDO EL PLUGIN DE ZABBIX [alexanderzobnin-zabbix-app]..."
 sleep 1

grafana-cli plugins install alexanderzobnin-zabbix-app

echo "$DAY : INICIANDO EL SERVICIO DE GRAFANA..."
 sleep 1

systemctl start grafana-server

echo "$DAY : HABILITARLO PARA EL ARRANQUE..."
echo

systemctl enable grafana-server.service

echo
echo "$DAY : VERIFICANDO EL ESTADO DEL SERVICIO grafana-server..."
 sleep 1
echo "$DAY : SERVER....................................."
echo
systemctl status grafana-server --no-pager
}


###################################
#             ZABBIX              #
###################################
ZaBBiX ()
{
DAY=$(date "+%H:%M:%S")

#
# Deshabilitar selinux (para evitar restricciones):
#

echo
echo "$DAY : COMENZANDO EL PROCESO DE INSTALACION ................"
echo "................................................................"
echo "................................................................"
 sleep 1
echo

InStALl_WGET

echo
echo "$DAY : DESHABILITANDO SELINUX (para evitar restricciones)..."

setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config

echo "$DAY : VERIFICANDO EL CAMBIO..."
echo
cat /etc/selinux/config | grep SELINUX=
echo
sleep 1

DAY=$(date "+%H:%M:%S")

# Instalacion de ultima version al 13/10/2020:

###################################
#     Agregado de repositorio     #
###################################

echo "$DAY : AGREGANDO REPOSITORIO NECESARIO PARA ZABBIX..."
echo
 sleep 1
yum install -y centos-release-scl
rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm
yum clean all

###################################
#        Instalando paquetes      #
###################################

DAY=$(date "+%H:%M:%S")

echo
echo "$DAY : INSTALANDO PAQUETES NECESARIOS DE ZABBIX................................................................................................................................."
 sleep 1

yum install -y httpd httpd-tools vim net-tools
yum install -y php php-cli php-common php-devel php-pear php-mbstring php-gd php-bcmath php-ctype php-xml php-xmlreader php-xmlwriter php-session php-mbstring php-gettext php-ldap

wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
wget http://rpms.remirepo.net/enterprise/remi-release-7.rpm
rpm -Uvh remi-release-7.rpm epel-release-latest-7.noarch.rpm
yum install -y yum-utils
yum-config-manager --enable remi-php72
yum update -y
yum install -y zabbix-web-mysql-scl zabbix-apache-conf-scl zabbix-server-mysql zabbix-agent --enablerepo=zabbix-frontend --skip-broken

rpm -Va --nofiles --nodigest
 sleep 1

# Se prepara la configuracion de Zabbix para que desde PHP se conecte al servicio de bases de datos:

PASSWORD=z4bb1xDBp4ss

cp -p /etc/zabbix/zabbix_server.conf /etc/zabbix/zabbix_server.conf.orig
sed "s/^# DBPassword=/DBPassword="$PASSWORD"/g" /etc/zabbix/zabbix_server.conf > /etc/zabbix/zabbix_server.conf-new
mv -f /etc/zabbix/zabbix_server.conf-new /etc/zabbix/zabbix_server.conf

DAY=$(date "+%H:%M:%S")

echo
echo "$DAY : INICIANDO LOS SERVICIOS DE ZABBIX..."
 sleep 1
systemctl stop zabbix-agent zabbix-server
systemctl start zabbix-server zabbix-agent

echo "$DAY : HABILITARLOS PARA EL ARRANQUE..."
echo
systemctl enable zabbix-server zabbix-agent

#######################################
# Verificacion de estado de servicios #
#######################################

DAY=$(date "+%H:%M:%S")

echo
echo "$DAY : VERIFICANDO EL ESTADO DEL SERVICIO zabbix-server, zabbix-agent..."
 sleep 1
echo "$DAY : SERVER....................................."
echo
systemctl status zabbix-server --no-pager
echo "$DAY : AGENTE....................................."
 sleep 1
echo
systemctl status zabbix-agent --no-pager


###################################
#       Configurar Zabbix         #
###################################

DAY=$(date "+%H:%M:%S")

echo "$DAY : CONFIGURANDO ZABBIX..."
echo "$DAY : OPTIMIZANDO VALORES DE (zabbix_server.conf)..."
echo "$DAY : ..................................................................................................................................................."
 sleep 1

>/etc/zabbix/zabbix_server.conf.temp

cat /etc/zabbix/zabbix_server.conf | while read LINE
do
        PARAMETERS="StartPollers StartPollersUnreachable StartPingers StartDBSyncers StartTrappers StartDiscoverers StartPreprocessors StartHTTPPollers StartAlerters StartTimers StartEscalators CacheSize HistoryCacheSize HistoryIndexCacheSize TrendCacheSize ValueCacheSize"

        echo "$LINE" >> /etc/zabbix/zabbix_server.conf.temp

        for i in $PARAMETERS
        do
                COUNTLINE=$(echo "$LINE" | grep "^# $i=" | wc -l | awk '{print $1}')

                if [ "$COUNTLINE" -ne 1 ]; then

                        STATUS="NOT-MATCH"
                else
                             case "$i" in
                                   StartPollers) echo "$LINE" | sed "s/$LINE/StartPollers=100/g" >> /etc/zabbix/zabbix_server.conf.temp
                                                 CHK=1 ;;
                        StartPollersUnreachable) echo "$LINE" | sed "s/$LINE/StartPollersUnreachable=50/g" >> /etc/zabbix/zabbix_server.conf.temp
                                                 CHK=1 ;;
                                   StartPingers) echo "$LINE" | sed "s/$LINE/StartPingers=50/g" >> /etc/zabbix/zabbix_server.conf.temp
                                                 CHK=1 ;;
                                 StartDBSyncers) echo "$LINE" | sed "s/$LINE/StartDBSyncers=4/g" >> /etc/zabbix/zabbix_server.conf.temp
                                                 CHK=1 ;;
                                  StartTrappers) echo "$LINE" | sed "s/$LINE/StartTrappers=10/g" >> /etc/zabbix/zabbix_server.conf.temp
                                                 CHK=1 ;;
                               StartDiscoverers) echo "$LINE" | sed "s/$LINE/StartDiscoverers=15/g" >> /etc/zabbix/zabbix_server.conf.temp
                                                 CHK=1 ;;
                             StartPreprocessors) echo "$LINE" | sed "s/$LINE/StartPreprocessors=15/g" >> /etc/zabbix/zabbix_server.conf.temp
                                                 CHK=1 ;;
                               StartHTTPPollers) echo "$LINE" | sed "s/$LINE/StartHTTPPollers=5/g" >> /etc/zabbix/zabbix_server.conf.temp
                                                 CHK=1 ;;
                                  StartAlerters) echo "$LINE" | sed "s/$LINE/StartAlerters=5/g" >> /etc/zabbix/zabbix_server.conf.temp
                                                 CHK=1 ;;
                                    StartTimers) echo "$LINE" | sed "s/$LINE/StartTimers=2/g" >> /etc/zabbix/zabbix_server.conf.temp
                                                 CHK=1 ;;
                                StartEscalators) echo "$LINE" | sed "s/$LINE/StartEscalators=2/g" >> /etc/zabbix/zabbix_server.conf.temp
                                                 CHK=1 ;;
                                      CacheSize) echo "$LINE" | sed "s/$LINE/CacheSize=128M/g" >> /etc/zabbix/zabbix_server.conf.temp
                                                 CHK=1 ;;
                               HistoryCacheSize) echo "$LINE" | sed "s/$LINE/HistoryCacheSize=64M/g" >> /etc/zabbix/zabbix_server.conf.temp
                                                 CHK=1 ;;
                          HistoryIndexCacheSize) echo "$LINE" | sed "s/$LINE/HistoryIndexCacheSize=32M/g" >> /etc/zabbix/zabbix_server.conf.temp
                                                 CHK=1 ;;
                                 TrendCacheSize) echo "$LINE" | sed "s/$LINE/TrendCacheSize=32M/g" >> /etc/zabbix/zabbix_server.conf.temp
                                                 CHK=1 ;;
                                 ValueCacheSize) echo "$LINE" | sed "s/$LINE/ValueCacheSize=256M/g" >> /etc/zabbix/zabbix_server.conf.temp
                                                 CHK=1 ;;
                                              *) echo "ERROR encontrado en parameter...!"
                                                 exit -1 ;;

                             esac
                fi

        done

done

mv /etc/zabbix/zabbix_server.conf.temp /etc/zabbix/zabbix_server.conf

DAY=$(date "+%H:%M:%S")

echo "$DAY : OPTIMIZANDO VALORES DE (zabbix_agentd.conf)..."
echo "$DAY : ..................................................................................................................................................."
 sleep 1

CHKHOST=$(hostname | awk '{print $1}')

sed -i "s/^Hostname=.*/Hostname=$CHKHOST/g" /etc/zabbix/zabbix_agentd.conf


###################################
#           Servicios             #
###################################

# Se reinician los servicios ya existentes (servicios web y de bases de datos):

echo "$DAY : REINICIANDO LOS SERVICIOS zabbix-server, zabbix-agent..."
 sleep 1

systemctl stop zabbix-agent zabbix-server
systemctl start zabbix-server zabbix-agent

#######################################
# Verificacion de estado de servicios #
#######################################

DAY=$(date "+%H:%M:%S")

echo "$DAY : VERIFICANDO EL ESTADO DE LOS SERVICIOS zabbix-server zabbix-agent..."
 sleep 1
echo
echo "$DAY : SERVER....................................."
echo
systemctl status zabbix-server --no-pager
 sleep 1
echo
echo "$DAY : AGENTE....................................."
echo
systemctl status zabbix-agent --no-pager


###################################
#            FIREWALL             #
###################################

DAY=$(date "+%H:%M:%S")

echo
echo "$DAY : ESTABLECIENDO REGLAS DE FIREWALL..."
 sleep 1
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --permanent --zone=public --add-port=10051/tcp
firewall-cmd --permanent --zone=public --add-port=10050/tcp
firewall-cmd --reload


###################################
#               PHP               #
###################################

DAY=$(date "+%H:%M:%S")

# Descomentar la linea php_value en /etc/php-fpm.d/zabbix.conf

echo "$DAY : CONFIGURANDO PARAMETROS DE PHP..."
 sleep 1

cp -p /etc/opt/rh/rh-php72/php-fpm.d/zabbix.conf /etc/opt/rh/rh-php72/php-fpm.d/zabbix.conf.orig
sed "s/; php_value/php_value/g" /etc/opt/rh/rh-php72/php-fpm.d/zabbix.conf > /etc/opt/rh/rh-php72/php-fpm.d/zabbix.conf-new
sed "s/New_York/Argentina\/Buenos_Aires/g" /etc/opt/rh/rh-php72/php-fpm.d/zabbix.conf-new > /etc/opt/rh/rh-php72/php-fpm.d/zabbix.conf

###################################
#         Configurar PHP          #
###################################

DAY=$(date "+%H:%M:%S")

echo "$DAY : CONFIGURANDO PHP..."
echo "$DAY : OPTIMIZANDO VALORES DE (/etc/php.ini)..."
echo "$DAY : ..................................................................................................................................................."
 sleep 1

>/etc/php.ini.temp

cat /etc/php.ini | while read LINE
do
        PARAMETERS="date.timezone memory_limit post_max_size upload_max_filesize max_execution_time max_input_time session.auto_start"

        echo "$LINE" >> /etc/php.ini.temp

        for i in $PARAMETERS
        do
                COUNTLINE=$(echo "$LINE" | grep "^;$i =" | wc -l | awk '{print $1}')

                if [ "$COUNTLINE" -ne 1 ]; then

                        STATUS="NOT-MATCH"
                else
                             case "$i" in
                                   date.timezone) echo "$LINE" | sed "s/$LINE/date.timezone = America\/Argentina\/Buenos_Aires/g" >> /etc/php.ini.temp
                                                 CHK=1 ;;
                                    memory_limit) echo "$LINE" | sed "s/$LINE/memory_limit = 128M/g" >> /etc/php.ini.temp
                                                 CHK=1 ;;
                                   post_max_size) echo "$LINE" | sed "s/$LINE/post_max_size = 16M/g" >> /etc/php.ini.temp
                                                 CHK=1 ;;
                             upload_max_filesize) echo "$LINE" | sed "s/$LINE/upload_max_filesize = 2M/g" >> /etc/php.ini.temp
                                                 CHK=1 ;;
                              max_execution_time) echo "$LINE" | sed "s/$LINE/max_execution_time = 300/g" >> /etc/php.ini.temp
                                                 CHK=1 ;;
                                  max_input_time) echo "$LINE" | sed "s/$LINE/max_input_time = 300/g" >> /etc/php.ini.temp
                                                 CHK=1 ;;
                              session.auto_start) echo "$LINE" | sed "s/$LINE/session.auto_start = 0/g" >> /etc/php.ini.temp
                                                 CHK=1 ;;
                                               *) echo "ERROR encontrado en parameter...!"
                                                 exit -1 ;;

                             esac
                fi

        done

done

mv /etc/php.ini.temp /etc/php.ini


#####################################
#   Verificando link del servicio   #
#####################################

if [ -f /usr/lib/systemd/system/php-fpm.service ]; then
        ST=OK
else
        ln -s /usr/lib/systemd/system/rh-php72-php-fpm.service /usr/lib/systemd/system/php-fpm.service
fi

####################################
# Inicio y  marca para el arranque #
####################################

DAY=$(date "+%H:%M:%S")

echo "$DAY : INICIANDO LOS SERVICIOS http, php-fpm..."
systemctl restart httpd php-fpm

echo "$DAY : HABILITARLOS PARA EL ARRANQUE..."
echo
systemctl enable httpd php-fpm

###################################
#  Verificacion post instalacion  #
###################################

httpd -v
 sleep 1
echo
php -v
 sleep 1

echo
echo "$DAY : VERIFICANDO EL ESTADO DEL SERVICIO zabbix-server..."

IP=$(ip a | grep inet | grep -v inet6 | tail -1 | awk 'BEGIN {FS="/"}{print $1}' | awk 'BEGIN {FS="inet"}{print $2}' | sed "s/ //g")

 sleep 1
echo
systemctl stop zabbix-agent
systemctl stop zabbix-server
systemctl start zabbix-server
systemctl start zabbix-agent
systemctl status zabbix-server --no-pager
echo
}


#######################################################

InStAlL "$OP"

#__END__.