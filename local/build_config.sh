#!/bin/bash
# workflow inputs 配置。
#
# export: 把本次 workflow_dispatch inputs 写成 build-config.json
# import: 读取 JSON。__action_workflow__ 必须与当前 workflow 文件名一致，否则拒绝导入。
#
# JSON 示例:
# {
#   "__action_workflow__": "fastbuild_6.6.89_mtk",
#   "ksu_type": "bakasu",
#   "susfs_enable": true,
#   "kernel_suffix": ""
# }
set -eu

usage() {
	echo "用法: $0 export <workflow文件名不含.yml> [输出文件]"
	echo "      $0 import <json文件> <当前workflow文件名不含.yml>"
	echo "export 读取环境变量中的 inputs；import 把 inputs 打到 stdout，供 eval。"
}

json_escape() {
	local s="${1-}"
	s="${s//\\/\\\\}"
	s="${s//\"/\\\"}"
	s="${s//$'\n'/\\n}"
	s="${s//$'\r'/\\r}"
	s="${s//$'\t'/\\t}"
	printf '%s' "$s"
}

json_bool() {
	case "${1-}" in
	true|True|TRUE) printf 'true' ;;
	*) printf 'false' ;;
	esac
}

shell_escape() {
	printf '%q' "${1-}"
}

# 只取顶层键，避免误匹配嵌套字段。
json_get() {
	local file="$1" key="$2" raw
	raw="$(grep -E "^[[:space:]]*\"${key}\"" "$file" | head -n 1 | sed -E 's/.*:[[:space:]]*//; s/,[[:space:]]*$//; s/^"//; s/"$//')"
	printf '%s' "$raw"
}

export_config() {
	local workflow="${1:?缺少 workflow 文件名}"
	local out="${2:-build-config.json}"
	{
		printf '{\n'
		printf '  "__action_workflow__": "%s",\n' "$(json_escape "$workflow")"
		printf '  "ksu_type": "%s",\n' "$(json_escape "${ksu_type:-bakasu}")"
		printf '  "susfs_enable": %s,\n' "$(json_bool "${susfs_enable:-false}")"
		printf '  "kpm_enable": %s,\n' "$(json_bool "${kpm_enable:-false}")"
		printf '  "lz4_enable": %s,\n' "$(json_bool "${lz4_enable:-false}")"
		printf '  "lz4kd_enable": %s,\n' "$(json_bool "${lz4kd_enable:-false}")"
		printf '  "bbr_enable": "%s",\n' "$(json_escape "${bbr_enable:-false}")"
		printf '  "droidspaces_enable": "%s",\n' "$(json_escape "${droidspaces_enable:-false}")"
		printf '  "better_net": %s,\n' "$(json_bool "${better_net:-false}")"
		printf '  "adios_enable": %s,\n' "$(json_bool "${adios_enable:-false}")"
		printf '  "rekernel_enable": %s,\n' "$(json_bool "${rekernel_enable:-false}")"
		printf '  "baseband_guard": %s,\n' "$(json_bool "${baseband_guard:-false}")"
		printf '  "ccache_update": %s,\n' "$(json_bool "${ccache_update:-false}")"
		printf '  "ccache_debug": %s,\n' "$(json_bool "${ccache_debug:-false}")"
		printf '  "kernel_suffix": "%s"\n' "$(json_escape "${kernel_suffix:-}")"
		printf '}\n'
	} > "$out"
	echo ">>> 已导出 ${workflow} 构建配置: $out"
}

import_config() {
	local file="${1:?缺少 json 文件}"
	local workflow="${2:?缺少当前 workflow 文件名}"
	if [[ ! -f "$file" ]]; then
		echo ">>> 未找到配置文件: $file" >&2
		return 1
	fi

	local tagged
	tagged="$(json_get "$file" __action_workflow__)"
	if [[ -z "$tagged" ]]; then
		echo ">>> ${file} 缺少 __action_workflow__，拒绝导入" >&2
		return 1
	fi
	if [[ "$tagged" != "$workflow" ]]; then
		echo ">>> 配置属于 ${tagged}，当前 workflow 是 ${workflow}，拒绝导入" >&2
		return 1
	fi

	local key val
	for key in ksu_type susfs_enable kpm_enable lz4_enable lz4kd_enable \
		bbr_enable droidspaces_enable better_net adios_enable rekernel_enable \
		baseband_guard ccache_update ccache_debug kernel_suffix; do
		val="$(json_get "$file" "$key")"
		printf '%s=%s\n' "$key" "$(shell_escape "$val")"
	done
	echo ">>> 已导入 ${tagged} 配置: ${file}" >&2
	return 0
}

cmd="${1:-}"
case "$cmd" in
export)
	export_config "${2:-}" "${3:-build-config.json}"
	;;
import)
	import_config "${2:-}" "${3:-}"
	;;
*)
	usage
	exit 1
	;;
esac
