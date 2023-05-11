#!/bin/bash
VERSION=3.7.3
sudo apt-get install m4
cd /tmp
wget https://ftp.gnu.org/gnu/nettle/nettle-${VERSION}.tar.gz
tar -xvf nettle-${VERSION}.tar.gz
cd nettle-${VERSION}
./configure && make && make install
# cp libnettle.so /usr/local/openresty/lualib
# cp libnettle.so /usr/local/openresty/luajit/lib/lua/5.1