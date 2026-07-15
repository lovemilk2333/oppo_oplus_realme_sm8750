#!/bin/bash
set -e

echo ">>> 正在进行通用 Patch..."

cd kernel_workspace || exit 255
cd common || exit 255

wget https://raw.githubusercontent.com/lovemilk2333/oppo_oplus_realme_sm8750/refs/heads/main/cve_patch/CVE-2026-43499.patch
patch -p1 -F 3 < CVE-2026-43499.patch || true
