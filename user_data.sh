#!/bin/bash
yum -y update
yum -y install httpd


myip=`curl ifconfig.me`

cat <<EOF > /var/www/html/index.html
<html>
<body bgcolor="black">
<h2><font color="gold">Build with Terraform by your greatness Zheni Ekoebve <font color="red"> v:1.6.4</font></h2><br><p>
<font color="green">Server PrivateIP: <font color="aqua">$myip<br><br>

<font color="magenta">
<b>Version 2.0 </b>
</body>
</html>
EOF

sudo service httpd start
chkconfig httpd on
