#!/usr/bin/env bash
set -Eeuo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/packaging/linux" "$fixture/scripts/lib"

cat > "$fixture/packaging/linux/control" <<'CONTROL'
Package: codex-desktop
Depends: build-essential, curl, dpkg, p7zip-full, pkexec | policykit-1, polkitd | policykit-1, python3, unzip, xdg-utils, libc6
CONTROL
cat > "$fixture/packaging/linux/codex-desktop.spec" <<'SPEC'
%if __PACKAGE_WITH_UPDATER__
Requires:       python3, /usr/bin/7z, polkit, curl, unzip, xdg-utils, gcc-c++, make
%else
Requires:       python3, /usr/bin/7z, curl, unzip, xdg-utils, gcc-c++, make
%endif
SPEC
printf '%s\n' 'package_with_updater_enabled() { :; }' > "$fixture/scripts/lib/package-common.sh"

bash "$repo_dir/scripts/prepare-upstream.sh" "$fixture"

grep -Fx 'Depends: curl, python3, xdg-utils, libc6' "$fixture/packaging/linux/control"
grep -Fx 'Requires:       python3, curl, xdg-utils' "$fixture/packaging/linux/codex-desktop.spec"
! grep -Eq 'build-essential|p7zip|policykit|polkit|unzip' "$fixture/packaging/linux/control"

# The overlay remains safe to run again on an already prepared checkout.
if bash "$repo_dir/scripts/prepare-upstream.sh" "$fixture" >/dev/null 2>&1; then
    echo 'Expected the second overlay application to reject the changed dependency shape.' >&2
    exit 1
fi

echo 'prepare-upstream tests passed'
