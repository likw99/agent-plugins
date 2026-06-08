#!/usr/bin/env bash
# Install the build-visionos-apps plugin into the Codex custom plugin cache by
# symlinking this repo-tracked source directory. The repo is the source of
# truth; the cache is regenerable. Re-run this if the cache is wiped.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="${HOME}/.codex/plugins/cache/custom"
DEST="${DEST_DIR}/build-visionos-apps"

mkdir -p "${DEST_DIR}"
ln -sfn "${SRC}" "${DEST}"

echo "Linked:"
echo "  ${DEST} -> ${SRC}"
echo
echo "Skills:"
ls -1 "${SRC}/skills" 2>/dev/null | sed 's/^/  - /' || echo "  (none yet)"
echo
echo "Restart Codex or refresh plugins to load build-visionos-apps."
