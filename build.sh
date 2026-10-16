#!/usr/bin/env bash
set -euo pipefail

# Shared build entry, versioned with the workspace manifest.
workspace_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <IDU-pre|IDU-rect|IDU-xfmr> <board> [west build options...]" >&2
    exit 2
fi


app_name="$1"
board_target="$2"
shift 2

case "$app_name" in
    IDU-pre|IDU-rect|IDU-xfmr) ;;
    *) echo "Unknown application: $app_name" >&2; exit 2 ;;
esac

if [[ ! -f "$workspace_dir/applications/$app_name/CMakeLists.txt" ]]; then
    echo "Missing applications/$app_name/CMakeLists.txt; create the application files first." >&2
    exit 1
fi

cd -- "$workspace_dir"
if [[ -z "${VIRTUAL_ENV:-}" && -f .venv/bin/activate ]]; then
    source .venv/bin/activate
fi

if [[ "${1:-}" == --mcuboot ]]; then
    if [[ "$app_name" != IDU-pre || "$board_target" != idu_pre ]]; then
        echo "MCUboot profile currently supports IDU-pre on idu_pre." >&2
        exit 2
    fi
    shift
    exec python3 applications/IDU-pre/tools/build_mcuboot.py "$@"
fi

build_dir="build/$app_name/$board_target"
west build -p auto -b "$board_target" \
    "applications/$app_name" -d "$build_dir" "$@"

hex_source="$build_dir/zephyr/$app_name.hex"
if [[ ! -f "$hex_source" ]]; then
    echo "HEX output missing: $hex_source. Enable CONFIG_BUILD_OUTPUT_HEX and set CONFIG_KERNEL_BIN_NAME to $app_name." >&2
    exit 1
fi

mkdir -p build/hex
if [[ "$app_name" == IDU-pre ]]; then
    python3 applications/IDU-pre/tools/check_boot_image.py \
        --bin "$build_dir/zephyr/$app_name.bin" --hex "$hex_source" \
        --output "$build_dir/zephyr/$app_name-boot-check.json"
fi
cp -- "$hex_source" "build/hex/$app_name.hex"
echo "HEX exported: $workspace_dir/build/hex/$app_name.hex"
