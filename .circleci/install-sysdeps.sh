#!/bin/bash
set -e

export DEBIAN_FRONTEND="noninteractive"
export TZ="Europe/London"

apt-get install -y make cmake \
lua5.3 liblua5.3-dev \
libgirepository1.0-dev libxwiimote-dev \
wget unzip
