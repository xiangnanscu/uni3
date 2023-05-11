#!/bin/bash -ex

# install openresty nodejs postgresql
# Note: Need to run this as root
#

# sshuttle --dns -r root@rsks.ren 0.0.0.0/0 -x rsks.ren
# https://github.com/ledgetech/lua-resty-http/issues/42

# chmod 700 ~/.ssh/*

# cp /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.pem

if [ -z $PGPASSWORD ]; then
  # read -p "please provide postgresql password for user postgres:" PGPASSWORD
  PGPASSWORD=postgres
else
  echo "pg password is provided: $PGPASSWORD"
fi
if [ -z $APP_NAME ]; then
  APP_NAME=xodel
else
  echo "app name is provided: $APP_NAME"
fi
PROJECT_DIR=$PWD
UBUNTU_VER=$(lsb_release -cs)
OPENRESTY_VER=1.21.4.1
OPENRESTY_DIR=/usr/local
OPENRESTY_PATH="${OPENRESTY_DIR}/openresty/bin:${OPENRESTY_DIR}/openresty/nginx/sbin:${OPENRESTY_DIR}/openresty/luajit/bin"
PATH="$OPENRESTY_PATH:$PATH"
BASH_RC=~/.profile

config_ssh() {
  # sudo sed -i 's/#\s*ClientAliveInterval 0/ClientAliveInterval 60/g' /etc/ssh/sshd_config
  # sudo sed -i 's/#\s*ClientAliveCountMax 3/ClientAliveCountMax 60/g' /etc/ssh/sshd_config
  # sudo sed -i 's/#\s*StrictHostKeyChecking ask/StrictHostKeyChecking no/g' /etc/ssh/ssh_config
  sudo echo 'ClientAliveInterval 60' >> /etc/ssh/sshd_config
  sudo echo 'ClientAliveCountMax 60' >> /etc/ssh/sshd_config
  sudo echo 'StrictHostKeyChecking no' >> /etc/ssh/ssh_config
  ssh-keygen -A
  sudo /etc/init.d/ssh restart
}

config_https() {
  sudo apt install snapd -y
  sudo snap install core; sudo snap refresh core
  apt-get remove certbot -y
  sudo snap install --classic certbot
  sudo ln -s /snap/bin/certbot /usr/bin/certbot
  certbot certonly --webroot -w /root/$PROJECT_DIR/dist -d $PROJECT_DIR.jahykj.cn
  sudo certbot renew --dry-run
}

config_cron() {
  # echo -e "10 5 * * * root cd ~/$APP_NAME && bin/pg-backup.py\n" >> /etc/crontab
  # echo -e "20 5 * * * root cd ~/$APP_NAME && bin/goaccess-stat.sh\n" >> /etc/crontab
  # # echo "cron.* /var/log/cron.log" >> cron.* /var/log/cron.log
  # # service rsyslog restart
  # service cron reload
  bin/config-cron.sh
}
install() {
  if [ -z $(which $1) ]; then
    sudo apt-get install -y $1
  else
    echo "$1 already installed"
  fi
}
npm_global_install() {
  if [ -z $(which $1) ]; then
    sudo npm install -g $1
  else
    echo "$1 already installed"
  fi
}

install_base() {
  sudo apt-get -q update
  install build-essential
  install unzip
  install make
  install gcc
  install libpcre3-dev
  install libssl-dev
  install perl
  install curl
  install zlib1g
  install zlib1g-dev
}

install_nodejs() {
  # nodejs
  if [ -z $(which node) ]; then
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs
  fi
  npm config set registry=https://registry.npmmirror.com
  npm_global_install yarn
  npm_global_install env-cmd
}

install_openresty_from_source() {
  cd /tmp
  if [ ! -f openresty-$1.tar.gz ]; then
    wget https://openresty.org/download/openresty-$1.tar.gz
  fi
  if [ ! -d openresty-$1/ ]; then
    tar -xvf openresty-$1.tar.gz
  fi
  if [ ! -d lua-nginx-module/ ]; then
    git clone --depth=1 https://github.com/openresty/lua-nginx-module.git
  fi
  if [ ! -d stream-lua-nginx-module/ ]; then
    git clone --depth=1 https://github.com/openresty/stream-lua-nginx-module.git
  fi
  if [ ! -d lua-resty-openssl-aux-module/ ]; then
    git clone --depth=1 https://github.com/fffonion/lua-resty-openssl-aux-module.git
  fi
  cd openresty-$1/
  #  --with-http_geoip_module
  ./configure --prefix=$2/openresty --with-pcre-jit -j8 \
    --add-module=/tmp/lua-resty-openssl-aux-module \
    --add-module=/tmp/lua-resty-openssl-aux-module/stream
  make -j4 && make install
}

install_openresty_from_apt() {
  # openresty
  sudo apt-get -y install --no-install-recommends wget gnupg ca-certificates

  if [ $UBUNTU_VER = jammy ]; then
    if [ ! -f /usr/share/keyrings/openresty.gpg ]; then
      wget -O - https://openresty.org/package/pubkey.gpg | sudo gpg --dearmor -o /usr/share/keyrings/openresty.gpg
    fi
  else
    wget -O - https://openresty.org/package/pubkey.gpg | sudo apt-key add -
  fi

  if [ ! -f /etc/apt/sources.list.d/openresty.list ]; then
    if [ $UBUNTU_VER = jammy ]; then
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/openresty.gpg] http://openresty.org/package/ubuntu $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/openresty.list > /dev/null
    else
      echo "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main"  | sudo tee /etc/apt/sources.list.d/openresty.list
    fi
  fi
  sudo apt-get -q update
  sudo apt-get -y install openresty
  service openresty stop
  # 禁止自带的openresty随系统启动
  systemctl disable openresty
}

install_openresty() {
  if [ ! -z "$(grep openresty/bin $BASH_RC)" ]; then
    echo "openresty path already written to ${BASH_RC}";
  else
    echo "export PATH=$OPENRESTY_PATH:\$PATH" >> ${BASH_RC};
  fi
  # install openresty
  if [ ! -f ${OPENRESTY_DIR}/openresty/bin/openresty ]; then
    install_openresty_from_source $OPENRESTY_VER $OPENRESTY_DIR
    # install_openresty_from_apt
  else
    echo "openresty already installed"
  fi
}

install_luarocks() {
  # luarocks
  LUAROCKS_VER='3.9.1'
  LUAROCKS_FD=luarocks-${LUAROCKS_VER}
  LUAROCKS_GZ=${LUAROCKS_FD}.tar.gz
  if [ ! -f ${OPENRESTY_DIR}/openresty/luajit/bin/luarocks ] && [ -f ${OPENRESTY_DIR}/openresty/bin/openresty ]; then
    cd /tmp
    if [ ! -f $LUAROCKS_GZ ]; then
      wget https://luarocks.org/releases/$LUAROCKS_GZ
    fi
    if [ ! -d $LUAROCKS_FD ]; then
      tar zxpf $LUAROCKS_GZ
    fi
    cd $LUAROCKS_FD
    ./configure --prefix=${OPENRESTY_DIR}/openresty/luajit \
        --with-lua=${OPENRESTY_DIR}/openresty/luajit/ \
        --lua-suffix=jit \
        --with-lua-include=${OPENRESTY_DIR}/openresty/luajit/include/luajit-2.1
    make && make install
    echo "luarocks ${LUAROCKS_VER} installed"
  else
    echo "luarocks already installed"
  fi
}

install_lua_packages() {
  if [ ! -z $(which opm) ]; then
    opm get spacewander/lua-resty-rsa
    opm get ledgetech/lua-resty-http
    opm get bungle/lua-resty-template
    opm get bungle/lua-resty-prettycjson
    opm get fffonion/lua-resty-openssl
    opm get xiangnanscu/pgmoon
    opm get xiangnanscu/lua-resty-inspect
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/xiangnanscu/lua-resty-rax/main/install.sh)"
  fi
  if [ ! -z $(which luarocks) ]; then
    # luarocks install  --tree lua_modules luasocket
    cd $PROJECT_DIR
    luarocks install busted
    luarocks install luaossl
    luarocks install luasocket
    luarocks install ljsyscall
    luarocks install lpeg
    luarocks install luacheck
    luarocks install argparse
    luarocks install xml2lua
    # luarocks install tl
  fi
}

install_postgresql() {
  # postgresql
  if [ -z "$(dpkg -l | grep -E '^ii\s+postgresql\s')" ]; then
    # add postgresql latest
    if [ $UBUNTU_VER != jammy ]; then
      sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
      wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
      sudo apt-get -q update
    fi
    # install postgresql
    sudo apt-get -y install postgresql

    PG_VERSION_VERBOSE=`pg_config --version`
    PG_VERSION=${PG_VERSION_VERBOSE:11:2}

    echo "pg version: $PG_VERSION"

    # modify setting
    sudo sed -i 's/max_connections = 100/max_connections = 400/g' /etc/postgresql/$PG_VERSION/main/postgresql.conf
    sudo sed -i 's/shared_buffers = 128MB/shared_buffers = 256MB/g' /etc/postgresql/$PG_VERSION/main/postgresql.conf
    sudo sed -i 's/#password_encryption = scram-sha-256/password_encryption = scram-sha-256/g' /etc/postgresql/$PG_VERSION/main/postgresql.conf
    # sudo sed -i 's/#password_encryption = scram-sha-256/password_encryption = md5/g' /etc/postgresql/$PG_VERSION/main/postgresql.conf
    # sudo sed -i 's/\(\s\)scram-sha-256/\1md5/g' /etc/postgresql/$PG_VERSION/main/pg_hba.conf
    echo "before restart, pg password: $PGPASSWORD, working dir: $PWD"
    sudo service postgresql restart
    sudo -u postgres psql -w postgres <<EOF
      ALTER USER postgres PASSWORD '$PGPASSWORD';
EOF

  fi
}


install_dotnet() {
  # install dotnet-sdk-6.0
  if [ -z $(which dotnet) ]; then
    wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb
    sudo apt-get update && sudo apt-get install -y dotnet-sdk-6.0
  fi
}

install_gh() {
  # github cli
  if [ -z $(which gh) ]; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt update \
    && sudo apt install gh -y
  fi
}

config_git() {
  if [ -z $(which git) ]; then
    sudo apt install git -y
  fi
  git config --global user.email "280145668@qq.com"
  git config --global user.name "xiangnan"
  git config --global receive.denyCurrentBranch updateInstead
  git config --global receive.advertisePushOptions true
  # https://www.jianshu.com/p/e050bb5629dd
  git config --global core.autocrlf input
}

prepare_django_pg() {
  sudo apt install python-is-python3
  sudo apt-get install postgresql postgresql-contrib -y
  sudo apt-get install libpq-dev python3-dev -y
  pip3 install psycopg2 -i https://pypi.tuna.tsinghua.edu.cn/simple
}

install_goaccess() {
  wget -O - https://deb.goaccess.io/gnugpg.key | gpg --dearmor | sudo tee /usr/share/keyrings/goaccess.gpg >/dev/null
  echo "deb [signed-by=/usr/share/keyrings/goaccess.gpg arch=$(dpkg --print-architecture)] https://deb.goaccess.io/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/goaccess.list
  sudo apt-get update
  sudo apt-get install goaccess -y
}

# config_ssh
# config_git
# install_base
# install_nodejs
# install_openresty
# install_luarocks
# install_lua_packages
# install_postgresql
# install_gh
# config_cron
# config_https
# install_goaccess
