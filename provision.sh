echo '==> Setting time zone'

timedatectl set-timezone $TIMEZONE
timedatectl | grep 'Time zone:' | xargs

# echo '==> Setting Centos 8 yum repositories'

# sed -i 's|^mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/CentOS-Linux-*
# sed -i 's|^#baseurl=http://mirror.centos.org|baseurl=http://vault.epel.cloud|g' /etc/yum.repos.d/CentOS-Linux-*

echo '==> Cleaning yum cache'

dnf -q -y makecache
rm -rf /var/cache/yum

echo '==> Installing Linux tools'

cp $VM_CONFIG_PATH/bashrc /home/vagrant/.bashrc
chown vagrant:vagrant /home/vagrant/.bashrc
dnf -q -y install nano tree zip unzip whois

echo '==> Installing Subversion and Git'

dnf -q -y install svn git

echo '==> Installing Apache'

dnf -q -y install httpd mod_ssl openssl
usermod -a -G apache vagrant
chown -R root:apache /var/log/httpd
cp $VM_CONFIG_PATH/localhost.conf /etc/httpd/conf.d/localhost.conf
cp $VM_CONFIG_PATH/virtualhost.conf /etc/httpd/conf.d/virtualhost.conf
sed -i 's|GUEST_SYNCED_FOLDER|'$GUEST_SYNCED_FOLDER'|' /etc/httpd/conf.d/virtualhost.conf
sed -i 's|FORWARDED_PORT_80|'$FORWARDED_PORT_80'|' /etc/httpd/conf.d/virtualhost.conf

echo '==> Fixing localhost SSL certificate'

if [ ! -f /etc/pki/tls/certs/localhost.crt ]; then
    cp $VM_CONFIG_PATH/localhost.crt /etc/pki/tls/certs/localhost.crt
    chmod u=rw /etc/pki/tls/certs/localhost.crt
fi
if [ ! -f /etc/pki/tls/private/localhost.key ]; then
    cp $VM_CONFIG_PATH/localhost.key /etc/pki/tls/private/localhost.key
    chmod u=rw /etc/pki/tls/private/localhost.key
fi

echo '==> Setting MariaDB 10.6 repository'

rpm --import --quiet https://mirror.rackspace.com/mariadb/yum/RPM-GPG-KEY-MariaDB
cp $VM_CONFIG_PATH/MariaDB.repo /etc/yum.repos.d/MariaDB.repo

echo '==> Installing MariaDB'

dnf -q -y install mariadb-server mariadb

echo '==> Setting PHP 8.1 repository'

rpm --import --quiet https://archive.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-8
dnf -q -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
rpm --import --quiet https://rpms.remirepo.net/RPM-GPG-KEY-remi
dnf -q -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
dnf -q -y module enable php:remi-8.1

echo '==> Installing PHP'

dnf -q -y install php php-cli php-common \
    php-bcmath php-devel php-gd php-intl php-ldap php-mcrypt php-mysqlnd \
    php-pear php-soap php-xdebug php-xmlrpc
cp /etc/httpd/conf.modules.d/00-mpm.conf /etc/httpd/conf.modules.d/00-mpm.conf~
cp $VM_CONFIG_PATH/00-mpm.conf /etc/httpd/conf.modules.d/00-mpm.conf
cp $VM_CONFIG_PATH/php.ini.htaccess /var/www/.htaccess
PHP_ERROR_REPORTING_INT=$(php -r 'echo '"$PHP_ERROR_REPORTING"';')
sed -i 's|PHP_ERROR_REPORTING_INT|'$PHP_ERROR_REPORTING_INT'|' /var/www/.htaccess

echo '==> Installing Python'

dnf -q -y install python2 python3

echo '==> Installing Adminer'

if [ ! -d /usr/share/adminer ]; then
    mkdir -p /usr/share/adminer
    curl -LsS https://www.adminer.org/latest-en.php -o /usr/share/adminer/adminer.php
    sed -i 's|login($we,$F){if($F=="")return|login($we,$F){if(true)|' /usr/share/adminer/adminer.php
    curl -LsS https://raw.githubusercontent.com/vrana/adminer/master/designs/nicu/adminer.css -o /usr/share/adminer/adminer.css
fi
cp $VM_CONFIG_PATH/adminer.conf /etc/httpd/conf.d/adminer.conf
sed -i 's|FORWARDED_PORT_80|'$FORWARDED_PORT_80'|' /etc/httpd/conf.d/adminer.conf

echo '==> Starting Apache'
if [ ! -L /etc/systemd/system/multi-user.target.wants/httpd.service ] ; then
    ln -s /usr/lib/systemd/system/httpd.service /etc/systemd/system/multi-user.target.wants/httpd.service
fi
apachectl configtest
systemctl start httpd
systemctl enable httpd

echo '==> Starting MariaDB'

if [ ! -L /etc/systemd/system/multi-user.target.wants/mariadb.service ] ; then
    ln -s /usr/lib/systemd/system/mariadb.service /etc/systemd/system/multi-user.target.wants/mariadb.service
fi
systemctl start mariadb
systemctl enable mariadb
mysqladmin -u root password ""

echo '==> Versions:'

cat /etc/redhat-release
echo $(openssl version)
echo $(curl --version | head -n1 | cut -d '(' -f 1)
echo $(svn --version | grep svn,)
echo $(git --version)
echo $(httpd -V | head -n1)
echo $(mysql -V)
echo $(php -v | head -n1)
echo $(python2 --version)
echo $(python3 --version)
