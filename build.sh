#!/usr/bin/env bash
set -euo pipefail

# Workspace dispatcher. Each application versions its own build entry.
workspace_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <application> <board> [build options...]" >&2
    exit 2
fi
app_name="$1"
shift
if [[ ! "$app_name" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]]; then
    echo "Invalid application name: $app_name" >&2
    exit 2
fi
entry="$workspace_dir/applications/$app_name/build.sh"
if [[ ! -x "$entry" ]]; then
    echo "Application build entry missing: $entry" >&2
    exit 1
fi
exec "$entry" "$@"
