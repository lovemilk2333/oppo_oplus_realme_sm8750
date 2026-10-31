#!/bin/bash
set -eu

echo ">>> 正在进行通用 Patch..."

# workflow 在 kernel_workspace/common 下调用，本地 builder 在仓库根目录调用。
# GitHub Actions 没有 checkout 本仓库，cve_patch 需要从当前分支拉下来。
REPO="${GITHUB_REPOSITORY:-lovemilk2333/oppo_oplus_realme_sm8750}"
REF="${GITHUB_REF_NAME:-main}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLEANUP=""

if [[ -n "${GITHUB_WORKSPACE:-}" && -d "${GITHUB_WORKSPACE}/cve_patch" ]]; then
	CVE_DIR="${GITHUB_WORKSPACE}/cve_patch"
elif [[ -d "${SCRIPT_DIR}/../cve_patch" ]]; then
	CVE_DIR="$(cd "${SCRIPT_DIR}/../cve_patch" && pwd)"
else
	CVE_DIR="$(mktemp -d /tmp/cve_patch.XXXXXX)"
	CLEANUP="${CVE_DIR}"
	trap 'rm -rf "${CLEANUP}"' EXIT
	echo ">>> 从 ${REPO}@${REF} 拉取 cve_patch/"
	api="https://api.github.com/repos/${REPO}/contents/cve_patch?ref=${REF}"
	names="$(wget -qO- "${api}" | grep -o '"name": "[^"]*\.patch"' | sed 's/"name": "//;s/"$//')"
	if [[ -z "${names}" ]]; then
		echo ">>> 仓库中没有 cve_patch/*.patch，跳过"
		exit 0
	fi
	while IFS= read -r name; do
		[[ -z "${name}" ]] && continue
		echo ">>> 下载 ${name}"
		wget -q -O "${CVE_DIR}/${name}" \
			"https://raw.githubusercontent.com/${REPO}/${REF}/cve_patch/${name}"
	done <<< "${names}"
fi

shopt -s nullglob
patches=("${CVE_DIR}"/*.patch)
shopt -u nullglob

if [[ ${#patches[@]} -eq 0 ]]; then
	echo ">>> ${CVE_DIR} 下没有 .patch 文件"
	exit 0
fi

echo ">>> CVE patch 目录: ${CVE_DIR}"
echo ">>> 共 ${#patches[@]} 个补丁"

for patch_file in "${patches[@]}"; do
	name="$(basename "${patch_file}")"
	echo ">>> 应用 ${name}"
	if patch -p1 -F 3 --forward --dry-run < "${patch_file}" >/tmp/cve_patch_dryrun.log 2>&1; then
		patch -p1 -F 3 --forward < "${patch_file}"
		echo ">>> ${name} 应用成功"
	else
		echo ">>> ${name} 未应用（可能已打过或上下文不匹配），继续"
		sed 's/^/    /' /tmp/cve_patch_dryrun.log || true
	fi
done

echo ">>> 通用 Patch 完成"
