#!/bin/bash
set -eu

echo ">>> 正在进行通用 Patch..."

wget https://raw.githubusercontent.com/$GITHUB_REPOSITORY/refs/heads/main/cve_patch/CVE-2026-43499.patch
patch -p1 -F 3 < CVE-2026-43499.patch || true

# CVE-2026-98260: exec POSIX timer UAF, cleanup right after de_thread()
wget https://raw.githubusercontent.com/$GITHUB_REPOSITORY/refs/heads/main/cve_patch/CVE-2026-98260.patch
patch -p1 -F 3 < CVE-2026-98260.patch || true
