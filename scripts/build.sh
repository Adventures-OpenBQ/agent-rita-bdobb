#!/usr/bin/env bash
# Copyright 2026 SecretoftheUniverse.com LLC. SPDX-License-Identifier: Apache-2.0
# Build the BDOBB Rita image locally: clone openbq-org/agent-rita at the commit pinned in
# sources.lock, verify it, apply patches/*.patch in order, and docker-build the patched tree
# for this machine. Nothing is pushed and no registry login is needed.
#   scripts/build.sh               # builds openbq-rita:6.0.0 (override with IMAGE=name:tag)
#   scripts/build.sh --check-only  # stop after clone, SHA check and patch application
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${WORK_DIR:-$ROOT/build/rita}"
IMAGE="${IMAGE:-openbq-rita:6.0.0}"

log() { echo "build.sh: $*" >&2; }
die() { log "$*"; exit 1; }

read -r _ URL SHA < <(awk '$1 == "rita" { print $1, $2, $3 }' "$ROOT/sources.lock") || true
[[ "${SHA:-}" =~ ^[0-9a-f]{40}$ ]] || die "sources.lock: no full 40-hex SHA for rita"

rm -rf "$WORK" && mkdir -p "$WORK" && git init -q "$WORK"
git -C "$WORK" fetch -q --depth 1 "$URL" "$SHA" || die "fetch of $SHA from $URL failed"
git -C "$WORK" checkout -q FETCH_HEAD
[ "$(git -C "$WORK" rev-parse HEAD)" = "$SHA" ] || die "HEAD is not the locked $SHA"
log "openbq-org/agent-rita $SHA verified"

for p in "$ROOT"/patches/*.patch; do
  [ -e "$p" ] || die "no patches in $ROOT/patches"
  git -C "$WORK" apply --check "$p" || die "patch does not apply: $(basename "$p")"
  git -C "$WORK" apply "$p"
  log "applied $(basename "$p")"
done

if [ "${1:-}" = "--check-only" ]; then log "check-only: OK"; exit 0; fi

# Rita bakes this into its service version; a checkout of this recipe names its commit.
VERSION="local"
if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  VERSION="sha-$(git -C "$ROOT" rev-parse --short=7 HEAD)"
  [ -z "$(git -C "$ROOT" status --porcelain)" ] || VERSION="$VERSION-dirty"
fi
docker build --build-arg GIT_SHA="$VERSION" \
  --label org.opencontainers.image.source=https://github.com/Adventures-OpenBQ/agent-rita-bdobb \
  --label org.opencontainers.image.revision="$SHA" \
  -t "$IMAGE" "$WORK" || die "docker build failed"
log "built $IMAGE ($VERSION, upstream $SHA)"
