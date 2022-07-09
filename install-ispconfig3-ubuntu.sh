#!/bin/bash
## Install ISPConfig3 on Ubuntu 20.04 64Bits
## Author: Nilton OS www.linuxpro.com.br
## https://www.howtoforge.com/tutorial/perfect-server-ubuntu-18.04-with-apache-php-myqsl-pureftpd-bind-postfix-doveot-and-ispconfig/
## https://www.howtoforge.com/tutorial/perfect-server-ubuntu-20.04-with-apache-php-myqsl-pureftpd-bind-postfix-doveot-and-ispconfig/
## https://www.howtoforge.com/replacing-amavisd-with-rspamd-in-ispconfig
## https://words.bombast.net/rspamd-with-postfix-dovecot-debian-stretch/
## https://www.howtoforge.com/community/threads/ispconfig-3-2-update.80587
## https://github.com/ahrasis/LE4ISPC
## Version 0.7


## Set lang en_US UTF8
## echo 'LC_ALL="en_US.utf8"' >>/etc/environment
## dpkg-reconfigure tzdata

# Check if user has root privileges
if [[ $EUID -ne 0 ]]; then
echo "You must run the script as root or using sudo"
   exit 1
fi


## Reconfigure Dash
echo "dash dash/sh boolean false" | debconf-set-selections
dpkg-reconfigure -f noninteractive dash > /dev/null 2>&1

MY_IP=$(ip a s|sed -ne '/127.0.0.1/!{s/^[ \t]*inet[ \t]*\([0-9.]\+\)\/.*$/\1/p}' | tr '\n' ' ')

echo -e "Set Server Name Ex: mail.seudominio.com.br : \c "
read  SERVER_FQDN

echo -e "Set Server IP Ex: $MY_IP : \c "
read  SERVER_IP

echo "" >>/etc/hosts
echo "$SERVER_IP  $SERVER_FQDN" >>/etc/hosts
hostnamectl set-hostname $SERVER_FQDN
echo "$SERVER_FQDN" > /proc/sys/kernel/hostname


## Stop and remove Apparmor, Sendmail
service apparmor stop
update-rc.d -f apparmor remove
apt-get remove -y apparmor apparmor-utils
service sendmail stop; update-rc.d -f sendmail remove

## Install VIM-NOX, SSH Server, Sudo, NTP
apt-get install -y software-properties-common apt-transport-https
apt-get install -y ssh openssh-server sudo ntp ntpdate
service sendmail stop; update-rc.d -f sendmail remove

## Install Softwares Mail Server
apt-get install -y postfix postfix-mysql mariadb-client mariadb-server
apt-get install -y openssl getmail4 binutils
apt-get install -y dovecot-pop3d dovecot-mysql dovecot-sieve dovecot-lmtpd dovecot-imapd
apt-get install -y amavisd-new spamassassin clamav clamav-daemon clamav-docs unzip bzip2 arj nomarch
apt-get install -y lzop cabextract apt-listchanges libnet-ldap-perl libauthen-sasl-perl daemon libio-string-perl
apt-get install -y libio-socket-ssl-perl libnet-ident-perl zip libnet-dns-perl postgrey libjson-perl


## Stop Spamassassin
service spamassassin stop
update-rc.d -f spamassassin remove
## freshclam -v

sed -i 's|AllowSupplementaryGroups false|AllowSupplementaryGroups true|' /etc/clamav/clamd.conf
freshclam
service clamav-daemon start


sed -i 's|bind-address|#bind-address|' /etc/mysql/mariadb.conf.d/50-server.cnf

## Backup Postfix
mkdir -p /etc/postfix/backup
cp -aR /etc/postfix/* /etc/postfix/backup/

## Backup Dovecot
mkdir -p /etc/dovecot/backup
cp -aR /etc/dovecot/* /etc/dovecot/backup/


## Config Postfix /etc/postfix/master.cf
sed -i 's|#submission|submission|' /etc/postfix/master.cf
sed -i 's|#  -o syslog_name=postfix/submission|  -o syslog_name=postfix/submission|' /etc/postfix/master.cf
sed -i 's|#  -o smtpd_tls_security_level=encrypt|  -o smtpd_tls_security_level=may|' /etc/postfix/master.cf
sed -i 's|#  -o smtpd_sasl_auth_enable=yes|  -o smtpd_sasl_auth_enable=yes|' /etc/postfix/master.cf
sed -i 's|#  -o smtpd_reject_unlisted_recipient=no|  -o smtpd_client_restrictions=permit_sasl_authenticated,reject|' /etc/postfix/master.cf

sed -i 's|#smtps|smtps|' /etc/postfix/master.cf
sed -i 's|#  -o syslog_name=postfix/smtps|  -o syslog_name=postfix/smtps|' /etc/postfix/master.cf
sed -i 's|#  -o smtpd_tls_wrappermode=yes|  -o smtpd_tls_wrappermode=yes|' /etc/postfix/master.cf
sed -i 's|#  -o smtpd_sasl_auth_enable=yes|  -o smtpd_sasl_auth_enable=yes|' /etc/postfix/master.cf
sed -i 's|#  -o smtpd_reject_unlisted_recipient=no|  -o smtpd_client_restrictions=permit_sasl_authenticated,reject|' /etc/postfix/master.cf

## Restart Postfix and Mysql
service postfix restart

mysql_secure_installation
service mariadb restart

echo 'mysql soft nofile 65535
mysql hard nofile 65535' >>/etc/security/limits.conf
mkdir /etc/systemd/system/mysql.service.d/
echo '[Service]
LimitNOFILE=infinity'>>/etc/systemd/system/mysql.service.d/limits.conf
systemctl daemon-reload; service mariadb restart

## Install Softwares Web Server
apt-get install -y apache2 apache2-doc apache2-utils libapache2-mod-php php php-common php-gd 
apt-get install -y php-mysql php-imap php-cli php-cgi libapache2-mod-fcgid apache2-suexec-pristine 
apt-get install -y php-pear mcrypt imagemagick php-curl php-intl php-pspell php-imagick
apt-get install -y php-sqlite3 php-tidy php-xmlrpc php-xsl php-memcache tinymce
apt-get install -y php-mbstring php-soap php-soap php-zip

apt-get install -y php-fpm

echo "<IfModule mod_headers.c>
    RequestHeader unset Proxy early
</IfModule>" | tee /etc/apache2/conf-available/httpoxy.conf


## Enable Softwares PHP and Apache2 modules
a2enmod suexec rewrite ssl actions include cgi proxy_fcgi
a2enmod dav_fs dav auth_digest headers actions fastcgi alias
a2enconf httpoxy

#apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xB4112585D386EB94
#add-apt-repository https://dl.hhvm.com/ubuntu
#apt-get update && apt-get install -y hhvm
#apt-get install -y hhvm
#echo 'hhvm.mysql.socket = /var/run/mysqld/mysqld.sock' >> /etc/hhvm/php.ini

service apache2 restart

## Install Let's Encrypt | 
apt-get install -y certbot
#mkdir /opt/certbot
#cd /opt/certbot
#wget https://dl.eff.org/certbot-auto
#chmod a+x ./certbot-auto && ./certbot-auto --install-only --non-interactive

 
## Install Softwares FTP Server
apt-get install -y pure-ftpd-common pure-ftpd-mysql quota quotatool libclass-dbi-mysql-perl
apt-get install -y bind9 dnsutils vlogger webalizer awstats geoip-database haveged
apt-get install -y build-essential autoconf automake libtool flex bison debhelper binutils

systemctl enable haveged
systemctl start haveged

rm -f /etc/cron.d/awstats
sed -i 's|VIRTUALCHROOT=false|VIRTUALCHROOT=true|' /etc/default/pure-ftpd-common
sed -i 's|application/x-ruby|#application/x-ruby|' /etc/mime.types

## echo 1 > /etc/pure-ftpd/conf/TLS
mkdir -p /etc/ssl/private/
openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem -subj "/C=SAO PAULO/ST=SAO PAULO/L=BR/O=Postfix/OU=Postfix/CN=$(hostname -f)"
chmod 600 /etc/ssl/private/pure-ftpd.pem
service pure-ftpd-mysql restart

### Install Rspamd
#apt-get install -y redis-server lsb-release
#CODENAME=$(lsb_release -c -s)
#wget -O- https://rspamd.com/apt-stable/gpg.key | apt-key add -
#echo "deb [arch=amd64] http://rspamd.com/apt-stable/ $CODENAME main" > /etc/apt/sources.list.d/rspamd.list
#echo "deb-src [arch=amd64] http://rspamd.com/apt-stable/ $CODENAME main" >> /etc/apt/sources.list.d/rspamd.list
#apt-get update && apt-get install -y rspamd

#echo 'servers = "127.0.0.1";' > /etc/rspamd/local.d/redis.conf
#echo "nrows = 2500;" > /etc/rspamd/local.d/history_redis.conf
#echo "compress = true;" >> /etc/rspamd/local.d/history_redis.conf
#echo "subject_privacy = false;" >> /etc/rspamd/local.d/history_redis.conf
#systemctl restart rspamd

## Disable Amavis
#systemctl stop amavisd-new
#systemctl disable amavisd-new

## Config Apache 2.4
#RewriteEngine On
#RewriteRule ^/rspamd/(.*) http://127.0.0.1:11334/$1 [P,L]
#<Location /rspamd>
#  Options FollowSymLinks
#  Require all granted
#</Location>


## Adicionando o Quota de forma automatica
#sed -i 's|defaults|defaults,usrjquota=quota.user,grpjquota=quota.group,jqfmt=vfsv0|' /etc/fstab
#mount -o remount /var/www
#quotacheck -avugm
#quotaon -avug

## Download ISPConfig 3.2.X
cd /tmp
get_isp=https://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz
wget -c ${get_isp}
tar xvfz $(basename ${get_isp})
cd ispconfig3_install/install && php -q install.php

## Install PHPMyadmin
## Para Instalar o PHPMyadmin Execute o Script abaixo
## https://gist.github.com/jniltinho/9af397c8ddb035a322b75aecce7cdeae
