#!/bin/bash
#Concept taken from fodor.xyz
#Install from Graylog Docs http://docs.graylog.org/en/2.3/pages/installation/os/ubuntu.html
#Approx. 12 min. install based on AWS EC2 t2.micro https://aws.amazon.com/ec2/instance-types/

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
GRYLOG_VER="2.3.X"
IPV4=$(hostname -i)
SECRET=$(pwgen -s 96 1)
ADMIN_PASSWORD="admin"
PWD=`pwd`
filename="${PWD}/graylog-${GRYLOG_VER}."$(date +"%d-%y-%b")""
logfile="${filename}.log"

clear
echo -e "
                                                       
                       ${Red}_a_a_a_a_.                      
                ${Red}_a_4XXXXXXXXXXXXXXXXa__                
             ${Red}_aOXOXXXXXXXXXXXXXXXXXXXX4XL_             
          ${Red}_jXUXOXXXXXXXXXXXXXXXXXXXXXXXXXX4L,          
        ${Red}_jXXXXXXXXXXXXXXXX2!3XXXXXXXXXXXXXXOXG_        
       ${Red}aOXXXOXXXXXXX""'          ""4OXXXXXXXXXXL,      
     ${Red}_dXOXXXXXXXO"'                  "4OXXXXXXXOX,     
    ${Red}_XXXXXXXXXX"                       -3XXXXXXXXXa    
   ${Red}_XXXXXXXXO7               ${White}_,          ${Red}"XXXXXXXXXs   
   ${Red}XXXXXXXXX7                ${White}++,          ${Red}-XXXXXXXXX,  
  ${Red}=4XXXXXXX7          ${White}.,    .]+=           ${Red}=XXXXXOXXn  
  ${Red}UXXXXXXXO          ${White}.++.   :+=+,           ${Red}*OXXXXXXXi 
 ${Red}?XXXXXXXOi          ${White}=]+;   +]-=;  ._       ${Red}=OXXXXXXXi 
 ${Red}=XXXXXXXXi    ${White}._,  ;]`:+  .]: ++,.++].      ${Red}XXXXOXXXX 
 ${Red}=4XXXXXOX(    ${White}+++++]` :+; :+` -=;=+`=`      ${Red}XXXXXXXXX 
 ${Red}=4XXXXXXXi    ${White}-~-      +] ++   =++/        ${Red}.XXXXXXXX2 
 ${Red}?XXXXXXXXL             ${White}:]_+;   :++         ${Red}?OXXXXOXXi 
  ${Red}XXXXXXXXXi             ${White}]+]:    -         ${Red}_XXXXXXXXX' 
  ${Red}=XXXXXOXXX,            ${White}=++              ${Red}.jXOXXXOXX7  
   ${Red}3XXXXXXXXX,           ${White}-+;             ${Red}.jXXXXXXXXX'  
    ${Red}4XXXXXXXXXn                         a3XXXXXXXXX'   
    ${Red}-3XXOXXXXXXXa                     _jXXXXXXXOXO'    
      ${Red}*OXXXXXXXXOXn_               _aO4UXXXXXXXX7'     
       ${Red}-XXXXOXXXXXXXXXa_a,   ._a_dXXOOXXXXXXXXX!       
         ${Red}"XXXXXXXXXXXXOXXXXXXX4XXUXXXXXXXXOXX"         
           ${Red}"*OOXXXOXXXXXXXXXXXXXXXXXXXXXXX7"           
              ${Red}"!XXXXXXOXXXXXXXXXXXXXXXX7"              
                  ${Red}-"""4XOXOXXXXX2!""^                  
"
echo -e "                         Installation Menu\n         ${Bold}Graylog v.${GRYLOG_VER} - Open Source Log Management\n" && tput sgr0
echo   
echo -n "${Blue}Please enter a password for the graylog admin [ENTER]: ${Yellow}"
read ADMIN_PASSWORD
ADMIN_PASSWORD=${ADMIN_PASSWORD:-admin}


#Prerequisites
apt update && sudo apt upgrade -y | tee -a $logfile
apt -y install apt-transport-https openjdk-8-jre-headless uuid-runtime pwgen | tee -a $logfile


#MongoDB (version included in 16.04 LTS)
apt -y install mongodb-server | tee -a $logfile


#Elasticsearch 5.x 
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add - | tee -a $logfile
echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-5.x.list >> $logfile  2>&1
apt update && apt -y install elasticsearch | tee -a $logfile

#Elasticsearch config
sed -i -e 's/#cluster.name: my-application$/cluster.name: graylog/g' /etc/elasticsearch/elasticsearch.yml
systemctl daemon-reload | tee -a $logfile
systemctl enable elasticsearch.service | tee -a $logfile
systemctl restart elasticsearch.service | tee -a $logfile


#Graylog 2.3.x
wget https://packages.graylog2.org/repo/packages/graylog-2.3-repository_latest.deb | tee -a $logfile
dpkg -i graylog-2.3-repository_latest.deb | tee -a $logfile
apt update && apt -y install graylog-server | tee -a $logfile

#Graylog config
sed -i -e "s/rest_listen_uri = http:\/\/127.0.0.1:9000\//rest_listen_uri = http:\/\/$IPV4:9000\//g" /etc/graylog/server/server.conf
sed -i -e "s/#web_listen_uri = http:\/\/127.0.0.1:9000\//web_listen_uri = http:\/\/$IPV4:9000\//g" /etc/graylog/server/server.conf
sed -i -e 's/password_secret =.*/password_secret = '$SECRET'/' /etc/graylog/server/server.conf
PASSWORD=$(echo -n $ADMIN_PASSWORD | sha256sum | awk '{print $1}')
sed -i -e 's/root_password_sha2 =.*/root_password_sha2 = '$PASSWORD'/' /etc/graylog/server/server.conf


#Cleanup & Startup
systemctl daemon-reload | tee -a $logfile
systemctl enable graylog-server.service | tee -a $logfile
systemctl start graylog-server.service | tee -a $logfile


#Final output confirmation
echo
echo "#######################################" >> $logfile  2>&1
echo "# Congrats the installation is finished" >> $logfile  2>&1
echo "# You should be able to view the app at" >> $logfile  2>&1
echo "#" >> $logfile  2>&1
echo "# http://$IPV4:9000" >> $logfile  2>&1
echo "# username: admin" >> $logfile  2>&1
echo "# password: $ADMIN_PASSWORD" >> $logfile  2>&1
echo "#" >> $logfile  2>&1
echo "# If you want to change the URL, please" >> $logfile  2>&1
echo "# read the docs http://docs.graylog.org" >> $logfile  2>&1
echo "#######################################" >> $logfile  2>&1
echo "Install log: ${logfile}" >> $logfile  2>&1
