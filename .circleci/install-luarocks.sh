#!/bin/bash
set -e

LR_VERSION=3.7.0

mkdir /tmp/luarocks
cd /tmp/luarocks

wget http://luarocks.org/releases/luarocks-"$LR_VERSION".tar.gz
tar -xf luarocks-"$LR_VERSION".tar.gz
cd luarocks-"$LR_VERSION"

./configure --lua-version=5.3
make bootstrap
