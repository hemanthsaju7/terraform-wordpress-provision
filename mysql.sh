#!/bin/bash
yum install mariadb-server -y ; systemctl restart mariadb.service ; systemctl enable mariadb.service
mysql_secure_installation <<EOF

y
secure123
secure123
y
y
y
y
EOF

mysql -u root -psecure123 -e  "CREATE DATABASE wordpress ;use wordpress;create user 'wordpress'@'%' identified by 'wordpress'; GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'%';FLUSH PRIVILEGES;"
