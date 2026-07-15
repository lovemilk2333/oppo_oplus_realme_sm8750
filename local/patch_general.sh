#!/bin/bash
set -e

wget https://github.com/cctv18/oppo_oplus_realme_sm8650/raw/refs/heads/main/cve_patch/CVE-2026-43499.patch
patch -p1 -F 3 < CVE-2026-43499.patch
