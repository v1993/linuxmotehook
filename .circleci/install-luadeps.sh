#!/bin/bash
set -e
mkdir deps

DEPSDIR="`pwd`/deps"

mkdir /tmp/luadeps
cd /tmp/luadeps

# Install lgi from git manually

git clone https://github.com/pavouk/lgi.git
cd lgi
make rock
luarocks make --tree "$DEPSDIR" lgi-*.rockspec
cd ..

# Install lua-xwiimote from dev server for now

luarocks install --server=https://luarocks.org/dev --tree "$DEPSDIR" lua-xwiimote

# Install crc32 from mainstream

luarocks install --tree "$DEPSDIR" crc32
