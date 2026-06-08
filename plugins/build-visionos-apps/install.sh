#!/usr/bin/env bash
# Install (or update) the build-visionos-apps plugin.
#
# Usage:
#   ./install.sh           — symlink this directory into the Codex plugin cache
#   ./install.sh --update  — git pull the repo first, then re-symlink
#
# The repo is the source of truth; the cache entry is just a symlink.
# Re-run any time the cache is wiped or after a pull.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="${HOME}/.codex/plugins/cache/custom"
DEST="${DEST_DIR}/build-visionos-apps"

# --update: pull latest from origin/main before (re-)linking
if [[ "${1:-}" == "--update" ]]; then
    echo "Pulling latest from origin/main..."
    git -C "${REPO_ROOT}" fetch --quiet origin
    git -C "${REPO_ROOT}" merge --ff-only origin/main
    echo
fi

mkdir -p "${DEST_DIR}"
ln -sfn "${SRC}" "${DEST}"

echo "Linked:"
echo "  ${DEST} -> ${SRC}"
echo
echo "Skills:"
ls -1 "${SRC}/skills" 2>/dev/null | sed 's/^/  - /' || echo "  (none yet)"
echo
echo "Restart Codex or refresh plugins to load build-visionos-apps."
