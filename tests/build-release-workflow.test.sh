#!/usr/bin/env bash
set -Eeuo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
workflow="$repo_dir/.github/workflows/build-release.yml"

grep -F "BUILD_SCHEMA_VERSION: '2'" "$workflow"
grep -F 'CACHIX_CACHE_NAME: ${{ vars.CACHIX_CACHE_NAME }}' "$workflow"
grep -F 'CACHIX_AUTH_TOKEN: ${{ secrets.CACHIX_AUTH_TOKEN }}' "$workflow"
grep -F 'release_key="${BUILD_SCHEMA_VERSION}|${RELEASE_ARCHITECTURE}|${CACHIX_CACHE_NAME}|${UPSTREAM_SOURCE_SHA}|${dmg_sha256}"' "$workflow"
grep -F 'name: Check out exact pristine upstream source' "$workflow"
grep -F 'ref: ${{ needs.probe.outputs.upstream_source_sha }}' "$workflow"
grep -F 'path: upstream-nix' "$workflow"
grep -F 'Verify the flake pins the selected DMG' "$workflow"
grep -F 'cachix push "$CACHIX_CACHE_NAME"' "$workflow"
grep -F 'needs: [heartbeat, probe, build, nix]' "$workflow"
grep -F "needs.nix.result == 'success'" "$workflow"

if grep -Eq 'uses:[[:space:]]+[^[:space:]]+@v[0-9]+' "$workflow"; then
    echo 'All third-party actions must be pinned to immutable commits.' >&2
    exit 1
fi

echo 'build-release workflow tests passed'
