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

# Install lua-xwiimote from mainstream

luarocks install --tree "$DEPSDIR" lua-xwiimote

# Install crc32 from mainstream

luarocks install --tree "$DEPSDIR" crc32

# Install lpeg (optional but good for parsing) from mainstream

luarocks install --tree "$DEPSDIR" lpeg
