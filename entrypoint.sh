#!/bin/bash
set -e

mkdir -p /workspace/mnt
chmod 755 /workspace/mnt

# Закрыть прямой доступ к "сырым" дискам — только через grant_access
chown root:root /host_mnt
chmod 700 /host_mnt

exec gosu aiuser "$@"