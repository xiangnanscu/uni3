#!/bin/bash -ex

OPENRESTY_VER=1.21.4.1
OPENRESTY_DIR=/usr/local

install_openresty_from_source() {
  cd /tmp
  wget https://openresty.org/download/openresty-$1.tar.gz
  tar -xvf openresty-$1.tar.gz
  git clone --depth=1 https://github.com/openresty/lua-nginx-module.git
  git clone --depth=1 https://github.com/openresty/stream-lua-nginx-module.git
  git clone --depth=1 https://github.com/fffonion/lua-resty-openssl-aux-module.git
  cd openresty-$1/
  #  --with-http_geoip_module
  ./configure --prefix=$2/openresty --with-pcre-jit -j8 \
    --add-module=/tmp/lua-resty-openssl-aux-module \
    --add-module=/tmp/lua-resty-openssl-aux-module/stream
  make -j4 && make install
}

install_openresty_from_source $OPENRESTY_VER $OPENRESTY_DIR