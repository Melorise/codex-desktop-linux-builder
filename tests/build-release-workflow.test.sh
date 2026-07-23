#!/usr/bin/env bash
set -Eeuo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
workflow="$repo_dir/.github/workflows/build-release.yml"

grep -F "BUILD_SCHEMA_VERSION: '5'" "$workflow"
grep -F 'CACHIX_CACHE_NAME: ${{ vars.CACHIX_CACHE_NAME }}' "$workflow"
grep -F 'CACHIX_PUBLIC_KEY: ${{ vars.CACHIX_PUBLIC_KEY }}' "$workflow"
grep -F 'CACHIX_AUTH_TOKEN: ${{ secrets.CACHIX_AUTH_TOKEN }}' "$workflow"
grep -F 'NIX_BRANCH_TOKEN: ${{ secrets.NIX_BRANCH_TOKEN }}' "$workflow"
grep -F 'token: ${{ secrets.NIX_BRANCH_TOKEN }}' "$workflow"
grep -F "CACHIX_PIN_NAME: codex-desktop-x86_64-linux" "$workflow"
grep -F "CACHIX_KEEP_REVISIONS: '3'" "$workflow"
grep -F 'release_key="${BUILD_SCHEMA_VERSION}|${RELEASE_ARCHITECTURE}|${CACHIX_CACHE_NAME}|${UPSTREAM_SOURCE_SHA}|${dmg_sha256}"' "$workflow"
grep -F 'name: Check out exact pristine upstream source' "$workflow"
grep -F 'ref: ${{ needs.probe.outputs.upstream_source_sha }}' "$workflow"
grep -F 'path: upstream-nix' "$workflow"
grep -F 'Verify the flake pins the selected DMG' "$workflow"
grep -F 'cachix push "$CACHIX_CACHE_NAME"' "$workflow"
grep -F 'cachix pin \' "$workflow"
grep -F -- '--keep-revisions "$CACHIX_KEEP_REVISIONS"' "$workflow"
grep -F 'nix_outputs='"'"'["codex-desktop"]'"'"'' "$workflow"
grep -F 'inputs.codex-desktop-linux.nixosModules.default' "$workflow"
grep -F 'extra-trusted-public-keys = [ "$cachix_public_key" ];' "$workflow"
grep -F 'name: Promote cached source to the Nix branch' "$workflow"
grep -F 'needs: [heartbeat, probe, build, nix]' "$workflow"
grep -F 'refs/remotes/nix-source/candidate:refs/heads/nix' "$workflow"
grep -F -- '--force-with-lease="refs/heads/nix:$current_sha"' "$workflow"
grep -F 'needs: [heartbeat, probe, build, nix, promote_nix_branch]' "$workflow"
grep -F "needs.promote_nix_branch.result == 'success'" "$workflow"
grep -F 'url = "$nix_flake_ref";' "$workflow"

awk '
  /name: Check out the successfully cached upstream source/ { in_checkout = 1; next }
  in_checkout && /fetch-depth: 0/ { found = 1 }
  in_checkout && /name: Promote the exact upstream commit/ { exit }
  END { exit(found ? 0 : 1) }
' "$workflow" || {
    echo 'The promoted upstream checkout must include full Git history.' >&2
    exit 1
}

if grep -Eq 'uses:[[:space:]]+[^[:space:]]+@v[0-9]+' "$workflow"; then
    echo 'All third-party actions must be pinned to immutable commits.' >&2
    exit 1
fi

if grep -Fq 'nix store gc' "$workflow"; then
    echo 'The ephemeral single-output Nix job must not run local store GC.' >&2
    exit 1
fi

for uncached_output in \
    '.#codex-desktop-computer-use-ui' \
    '.#codex-desktop-remote-mobile-control' \
    '.#codex-desktop-computer-use-ui-remote-mobile-control' \
    '.#checks.x86_64-linux.watchdog-linux-features' \
    '.#installer'; do
    if grep -Fq "$uncached_output" "$workflow"; then
        echo "Unexpected Cachix output remains in workflow: $uncached_output" >&2
        exit 1
    fi
done

echo 'build-release workflow tests passed'
