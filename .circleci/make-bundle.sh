#!/bin/bash
set -e

mkdir /tmp/artifacts

tar -pcvz --transform 's,^,linuxmotehook/,' -f  /tmp/artifacts/linuxmotehook-bundle.tar.gz \
*.lua \
README.md LICENSE \
deps/lib/lua deps/share
