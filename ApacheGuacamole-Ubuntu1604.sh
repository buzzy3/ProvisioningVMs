#!/bin/bash
# Script logic from  https://github.com/MysticRyuujin/guac-install/blob/master/guac-install.sh
# Graphic from https://sourceforge.net/projects/guacamoleinstallscript/

# Version numbers of Guacamole and MySQL Connector/J to download
VERSION="0.9.13"
MCJVERSION="5.1.43"

Black=`tput setaf 0`   #${Black}
Red=`tput setaf 1`     #${Red}
Green=`tput setaf 2`   #${Green}
Yellow=`tput setaf 3`  #${Yellow}
Blue=`tput setaf 4`    #${Blue}
Magenta=`tput setaf 5` #${Magenta}
Cyan=`tput setaf 6`    #${Cyan}
White=`tput setaf 7`   #${White}
Bold=`tput bold`       #${Bold}
Rev=`tput smso`        #${Rev}
Reset=`tput sgr0`      #${Reset}
Bold=`tput bold`       #${Bold}

clear
echo -e "
                                                                 
                                                                 
                                                ${Yellow}'.'              
                            ${Green}'.:///:-.....'     ${Yellow}-yyys/-           
                     ${Green}.://///++++++++++++++/-  ${Yellow}.yhhhhhys/'        
                  ${Green}'.:++++++++++++++++++++++: ${Yellow}'yhhhhhhhhy-        
          ${White}.+y' ${Green}'://++++++++++++++++++++++++' ${Yellow}':yhhhhyo:'         
        ${White}-yNd. ${Green}'/+++++++++++++++++++++++++++//' ${Yellow}.+yo:' ${White}'::        
       ${White}oNMh' ${Green}./++++++++++++++++++++++++++++++/:' '''' ${White}'mMh.      
      ${White}-MMM:  ${Green}/+++++++++++++++++++++++++++++++++-.:/+:  ${White}yMMs      
      ${White}-MMMs  ${Green}./++++++++++++++++++++++++++++++++++++/' ${White}.mMMy      
      ${White}'NMMMy. ${Green}'-/+++++++++++++++++++++++++++++++/:.  ${White}:dMMMo      
       ${White}+MMMMNy:' ${Green}'.:///++++++++++++++++++++//:-.' ${White}./hMMMMN'      
       ${White}-MMMMMMMmy+-.${Green}''''.---::::::::::--..''''${White}.:ohNMMMMMMy       
        ${White}sNMMMMMMMMMmdhs+/:${Green}--..........--${White}:/oyhmNMMMMMMMMMd-       
         ${White}.+dNMMMMMMMMMMMMMMNNmmmmmmmNNNMMMMMMMMMMMMMMmy:'        
            ${White}./sdNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNmho:'           
          ${White}'     .:+shmmNNMMMMMMMMMMMMMMMMNNmdyo/-'               
          ${White}.o:.       '.-::/+ossssssso++/:-.'       '-/'          
           ${White}.ymh+-.'                           ''./ydy.           
             ${White}/dMMNdyo/-.''''         ''''.-:+shmMNh:             
               ${White}:yNMMMMMMNmdhhyyyyyyyhhdmNNMMMMMNy:               
                 ${White}':sdNNMMMMMMMMMMMMMMMMMMMNNds:'                 
                     ${White}'-/+syhdmNNNNNNmdhyo/-'                     
"
echo -e "                         Installation Menu\n         ${Bold}Guacamole Remote Desktop Gateway ${VERSION}\n" && tput sgr0
echo 

# Grab a password for MySQL Root
read -s -p "Enter the password that will be used for MySQL Root: " mysqlrootpassword
echo
debconf-set-selections <<< "mysql-server mysql-server/root_password password $mysqlrootpassword"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $mysqlrootpassword"

# Grab a password for Guacamole database user account
read -s -p "Enter the password that will be used for the Guacamole database: " guacdbuserpassword
echo

# Update apt so we can search apt-cache for newest tomcat version supported
apt update

# tomcat8 is newest, tomcat7 and tomcat6 should work too
if [ $(apt-cache search "^tomcat8$" | wc -l) -gt 0 ]; then
    TOMCAT="tomcat8"
elif [ $(apt-cache search "^tomcat7$" | wc -l) -gt 0 ]; then
    TOMCAT="tomcat7"
else
    TOMCAT="tomcat6"
fi

# If you want to force a specific tomcat install and not go with the newest just set it here and uncomment:
#TOMCAT=""

# Ubuntu and Debian have different names of the libjpeg-turbo library for some reason...
if [ `egrep -c "ID=ubuntu" /etc/os-release` -gt 0 ]
then
    JPEGTURBO="libjpeg-turbo8-dev"
else
    JPEGTURBO="libjpeg62-turbo-dev"
fi

# Ubuntu 16.10 has a different name for libpng12-dev for some reason...
if [ `egrep -c 'VERSION="16.10' /etc/os-release` -gt 0 ]
then
    LIBPNG="libpng-dev"
else
    LIBPNG="libpng12-dev"
fi

# Install features
apt -y install build-essential libcairo2-dev ${JPEGTURBO} ${LIBPNG} libossp-uuid-dev libavcodec-dev libavutil-dev \
libswscale-dev libfreerdp-dev libpango1.0-dev libssh2-1-dev libtelnet-dev libvncserver-dev libpulse-dev libssl-dev \
libvorbis-dev libwebp-dev mysql-server mysql-client mysql-common mysql-utilities ${TOMCAT} freerdp ghostscript jq wget curl dpkg-dev

# If apt fails to run completely the rest of this isn't going to work...
if [ $? != 0 ]; then
    echo "apt failed to install all required dependencies"
    exit
fi

# Get build-folder
BUILD_FOLDER=$(dpkg-architecture -qDEB_BUILD_GNU_TYPE)

SERVER=$(curl -s 'https://www.apache.org/dyn/closer.cgi?as_json=1' | jq --raw-output '.preferred|rtrimstr("/")')

# Add GUACAMOLE_HOME to $TOMCAT ENV
echo "" >> /etc/default/${TOMCAT}
echo "# GUACAMOLE ENV VARIABLE" >> /etc/default/${TOMCAT}
echo "GUACAMOLE_HOME=/etc/guacamole" >> /etc/default/${TOMCAT}

# Download Guacamole files
wget ${SERVER}/incubator/guacamole/${VERSION}-incubating/source/guacamole-server-${VERSION}-incubating.tar.gz
wget ${SERVER}/incubator/guacamole/${VERSION}-incubating/binary/guacamole-${VERSION}-incubating.war
wget ${SERVER}/incubator/guacamole/${VERSION}-incubating/binary/guacamole-auth-jdbc-${VERSION}-incubating.tar.gz
wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MCJVERSION}.tar.gz

# Extract Guacamole files
tar -xzf guacamole-server-${VERSION}-incubating.tar.gz
tar -xzf guacamole-auth-jdbc-${VERSION}-incubating.tar.gz
tar -xzf mysql-connector-java-${MCJVERSION}.tar.gz

# Make directories
mkdir -p /etc/guacamole/lib
mkdir -p /etc/guacamole/extensions

# Install guacd
cd guacamole-server-${VERSION}-incubating
./configure --with-init-dir=/etc/init.d
make
make install
ldconfig
systemctl enable guacd
cd ..

# Move files to correct locations
mv guacamole-${VERSION}-incubating.war /etc/guacamole/guacamole.war
ln -s /etc/guacamole/guacamole.war /var/lib/${TOMCAT}/webapps/
ln -s /usr/local/lib/freerdp/guac*.so /usr/lib/${BUILD_FOLDER}/freerdp/
cp mysql-connector-java-${MCJVERSION}/mysql-connector-java-${MCJVERSION}-bin.jar /etc/guacamole/lib/
cp guacamole-auth-jdbc-${VERSION}-incubating/mysql/guacamole-auth-jdbc-mysql-${VERSION}-incubating.jar /etc/guacamole/extensions/

# Configure guacamole.properties
echo "mysql-hostname: localhost" >> /etc/guacamole/guacamole.properties
echo "mysql-port: 3306" >> /etc/guacamole/guacamole.properties
echo "mysql-database: guacamole_db" >> /etc/guacamole/guacamole.properties
echo "mysql-username: guacamole_user" >> /etc/guacamole/guacamole.properties
echo "mysql-password: $guacdbuserpassword" >> /etc/guacamole/guacamole.properties
rm -rf /usr/share/${TOMCAT}/.guacamole
ln -s /etc/guacamole /usr/share/${TOMCAT}/.guacamole

# restart tomcat
service ${TOMCAT} restart

# Create guacamole_db and grant guacamole_user permissions to it

# SQL code
SQLCODE="
create database guacamole_db;
create user 'guacamole_user'@'localhost' identified by \"$guacdbuserpassword\";
GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole_db.* TO 'guacamole_user'@'localhost';
flush privileges;"

# Execute SQL code
echo $SQLCODE | mysql -u root -p$mysqlrootpassword

# Add Guacamole schema to newly created database
cat guacamole-auth-jdbc-${VERSION}-incubating/mysql/schema/*.sql | mysql -u root -p$mysqlrootpassword guacamole_db

# Cleanup
rm -rf guacamole-*
rm -rf mysql-connector-java-${MCJVERSION}*
