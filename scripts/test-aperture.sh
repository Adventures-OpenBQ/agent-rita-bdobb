#!/usr/bin/env bash
# Copyright 2026 SecretoftheUniverse.com LLC. Apache-2.0.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${WORK_DIR:-$ROOT/build/rita}"
TEST_IMAGE="${TEST_IMAGE:-oven/bun:1.4.4-slim}"
[ -f "$WORK/package.json" ] || { echo "Run scripts/build.sh --check-only first" >&2; exit 2; }
args=(--rm --memory 2g --label com.adventures.audit=rita-aperture --mount "type=bind,source=$WORK,target=/app" --workdir /app)
# Dependencies live only in this generated Linux checkout. Provider tests use
# local HTTP servers; the complete test phase has no external network access.
docker run "${args[@]}" "$TEST_IMAGE" bun install --frozen-lockfile
docker run "${args[@]}" --network none "$TEST_IMAGE" bun test tests/
docker run "${args[@]}" "$TEST_IMAGE" bun x --package typescript@5.9.3 tsc --noEmit
