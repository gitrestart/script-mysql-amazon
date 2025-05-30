#!/bin/bash

# Variáveis
DB_NAME="world"
SQL_URL="https://raw.githubusercontent.com/gitrestart/script-mysql-amazon/master/world.sql"
MYSQL_PASS="re:St@rt!9"

# Verifica se está como root
if [ "$EUID" -ne 0 ]; then
 echo "Por favor, execute como root"
 exit 1
fi

# Atualiza pacotes
yum update -y

# Instala EPEL e repositório do MySQL
amazon-linux-extras install epel -y
yum install -y https://dev.mysql.com/get/mysql80-community-release-el7-5.noarch.rpm

# Desabilita verificação GPG do repositório do MySQL
sed -i 's/gpgcheck=1/gpgcheck=0/' /etc/yum.repos.d/mysql-community.repo

# Instala o MySQL Server
yum install -y mysql-community-server

# Ativa e inicia o serviço mysqld
systemctl enable mysqld
systemctl start mysqld

# Aguarda o mysqld gerar a senha temporária
sleep 10

# Obtém a senha temporária
TEMP_PASS=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')
echo "Senha temporária do root extraída: $TEMP_PASS"

# Instala o expect para automação
yum install -y expect

# Executa mysql_secure_installation automaticamente
expect <<EOF
spawn mysql_secure_installation
expect "Enter password for user root:"
send "$TEMP_PASS\r"
expect "New password:"
send "$MYSQL_PASS\r"
expect "Re-enter new password:"
send "$MYSQL_PASS\r"
expect "Change the password for root ?"
send "n\r"
expect "Remove anonymous users?"
send "y\r"
expect "Disallow root login remotely?"
send "y\r"
expect "Remove the test database and access to it?"
send "y\r"
expect "Reload privilege tables now?"
send "y\r"
expect eof
EOF

echo "[+] Baixando arquivo SQL de $SQL_URL..."
curl -L -o /tmp/$DB_NAME.sql "$SQL_URL"

# Criando e importação do banco de dados
echo "[+] Criando banco de dados $DB_NAME..."
echo "[+] Importando $DB_NAME.sql para $DB_NAME..."
mysql -u root --password=$MYSQL_PASS < /tmp/$DB_NAME.sql

# Mensagem final
echo "[+] MySQL instalado e configurado com sucesso!"
echo "[+] A senha do root é: $MYSQL_PASS"
echo "[+] Acesse com:  mysql -u root --password=$MYSQL_PASS"
