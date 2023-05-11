#!/bin/bash -ex

sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get -q update
sudo apt-get -y install postgresql
service postgresql start
sudo sed -i 's/#password_encryption = scram-sha-256/password_encryption = scram-sha-256/g' /etc/postgresql/15/main/postgresql.conf
sudo cat /etc/postgresql/15/main/postgresql.conf|grep pass
service postgresql reload
sudo -u postgres psql -w postgres <<EOF
  ALTER USER postgres PASSWORD 'postgres';
  SELECT rolname,rolpassword FROM pg_authid WHERE rolcanlogin;
EOF