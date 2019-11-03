#!/bin/bash

sudo apt-get -qq -y update
sudo apt-get install -y wget unzip dnsutils ntp git dnsmasq-base dnsmasq telnet vim netcat jq
sudo systemctl start ntp.service
sudo systemctl enable ntp.service
echo "Disable reverse dns lookup in SSH"
sudo sh -c 'echo "\nUseDNS no" >> /etc/ssh/sshd_config'
sudo service ssh restart
sudo ufw disable

echo "Update resolv.conf"
sudo sed -i '1i nameserver 127.0.0.1\n' /etc/resolv.conf

echo "Configuring dnsmasq to forward .consul requests to consul port 8600"
sudo tee /etc/dnsmasq.d/consul > /dev/null <<DNSMASQ
server=/consul/127.0.0.1#8600
DNSMASQ

echo "Enable and restart dnsmasq"
sudo systemctl enable dnsmasq
sudo systemctl restart dnsmasq

echo "Installing Consul..."
cd /tmp
CONSUL_VERSION="1.6.1"
sudo curl https://releases.hashicorp.com/consul/$${CONSUL_VERSION}/consul_$${CONSUL_VERSION}_linux_amd64.zip -o consul.zip
sudo unzip consul.zip

sudo install /tmp/consul /usr/bin/consul
(
cat <<-EOF
	[Unit]
	Description=consul agent
	Requires=network-online.target
	After=network-online.target
	[Service]
	Restart=on-failure
	ExecStart=/usr/bin/consul agent -config-dir=/etc/consul.d
	ExecReload=/bin/kill -HUP $MAINPID
	[Install]
	WantedBy=multi-user.target
EOF
) | sudo tee /etc/systemd/system/consul.service

sudo mkdir -p /etc/consul.d
sudo chmod a+w /etc/consul.d
sudo rm -f /tmp/consul.zip

sudo cat << EOF > /etc/consul.d/config.json
{
  "server": true,
  "datacenter": "dc2",
  "bootstrap_expect": 1,
  "leave_on_terminate": true,
  "advertise_addr": "$(/sbin/ifconfig ens5 | grep 'inet ' | awk '{print substr($2,1)}')",
  "data_dir": "/opt/consul/data",
  "client_addr": "0.0.0.0",
  "log_level": "INFO",
  "ui": true
}
EOF

sudo service consul start

#Mariadb install
sudo apt-get install -y mariadb-server
sudo mysqladmin -u root password R00tPassword
sudo mysql -u root -p'R00tPassword' << EOF
GRANT ALL PRIVILEGES ON *.* TO 'vaultadmin'@'%' IDENTIFIED BY 'vaultadminpassword' WITH GRANT OPTION;
CREATE DATABASE app;
FLUSH PRIVILEGES;
EOF
sudo sed -i 's/bind-address/#bind-address/g' /etc/mysql/mariadb.conf.d/50-server.cnf
sudo service mysql restart;
#mysql -h $(dig +short mariadb.service.consul | sed -n 1p) -u vaultadmin -pvaultadminpassword


#Mariadb Consul service
echo '{"service": {"name": "mariadb", "tags": ["mariadb"], "port":3306}}' | sudo tee /etc/consul.d/mysql.json

sudo service consul restart

#Connect Install
