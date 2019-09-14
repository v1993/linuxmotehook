#!/bin/bash
set -e

mkdir /tmp/luarocks
cd /tmp/luarocks

wget http://luarocks.org/releases/luarocks-3.2.1.tar.gz
tar -xf luarocks-3.2.1.tar.gz
cd luarocks-3.2.1/

./configure --lua-version=5.3
make bootstrap
