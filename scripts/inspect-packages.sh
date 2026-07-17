#!/usr/bin/env bash
set -Eeuo pipefail

upstream_dir="${1:?usage: inspect-packages.sh UPSTREAM_DIR}"
package_version="${PACKAGE_VERSION:?PACKAGE_VERSION is required}"
expected_dmg_sha256="${EXPECTED_DMG_SHA256:?EXPECTED_DMG_SHA256 is required}"
expected_upstream_sha="${EXPECTED_UPSTREAM_SOURCE_SHA:?EXPECTED_UPSTREAM_SOURCE_SHA is required}"

shopt -s nullglob
debs=("$upstream_dir"/dist/*.deb)
rpms=("$upstream_dir"/dist/*.rpm)
appimages=("$upstream_dir"/dist/*.AppImage)
[ "${#debs[@]}" -eq 1 ]
[ "${#rpms[@]}" -eq 1 ]
[ "${#appimages[@]}" -eq 1 ]
deb="$(realpath "${debs[0]}")"
rpm_file="$(realpath "${rpms[0]}")"
appimage="$(realpath "${appimages[0]}")"

test "$(dpkg-deb -f "$deb" Package)" = codex-desktop
test "$(dpkg-deb -f "$deb" Version)" = "$package_version"
test "$(dpkg-deb -f "$deb" Architecture)" = amd64
deb_dependencies="$(dpkg-deb -f "$deb" Depends)"
test -n "$deb_dependencies"
for dependency in build-essential dpkg p7zip-full pkexec policykit-1 polkitd polkit unzip; do
    if grep -Eq "(^|[ ,|])${dependency}([ ,|]|$)" <<<"$deb_dependencies"; then
        echo "Updater-only dependency leaked into the DEB: $dependency" >&2
        exit 1
    fi
done

test "$(rpm -qp --qf '%{NAME}' "$rpm_file")" = codex-desktop
test "$(rpm -qp --qf '%{VERSION}' "$rpm_file")" = "${package_version%%+*}"
test "$(rpm -qp --qf '%{RELEASE}' "$rpm_file")" = "${package_version#*+}"
test "$(rpm -qp --qf '%{ARCH}' "$rpm_file")" = x86_64
rpm -qp --requires "$rpm_file" > /tmp/codex-builder-rpm-requires.txt
for dependency in /usr/bin/7z gcc-c++ make polkit unzip; do
    if grep -Fxq "$dependency" /tmp/codex-builder-rpm-requires.txt; then
        echo "Updater-only dependency leaked into the RPM: $dependency" >&2
        exit 1
    fi
done

inspect_root="$(mktemp -d)"
trap 'rm -rf "$inspect_root"' EXIT
mkdir -p "$inspect_root/deb" "$inspect_root/rpm" "$inspect_root/appimage"
dpkg-deb -x "$deb" "$inspect_root/deb"
(
    cd "$inspect_root/rpm"
    rpm2cpio "$rpm_file" | cpio -idm --quiet
)
chmod 0755 "$appimage"
(
    cd "$inspect_root/appimage"
    "$appimage" --appimage-extract >/dev/null
)

check_native_payload() {
    local root="$1"
    test -x "$root/opt/codex-desktop/start.sh"
    test -x "$root/opt/codex-desktop/electron"
    test -f "$root/opt/codex-desktop/content/webview/index.html"
    test -f "$root/opt/codex-desktop/resources/codex-linux-build-info.json"
    test -f "$root/usr/share/applications/codex-desktop.desktop"
    test -f "$root/usr/share/icons/hicolor/256x256/apps/codex-desktop.png"
    test ! -e "$root/usr/bin/codex-update-manager"
    test ! -e "$root/usr/lib/systemd/user/codex-update-manager.service"
    test ! -e "$root/usr/share/polkit-1/actions/com.github.ilysenko.codex-desktop-linux.update.policy"
    test ! -e "$root/opt/codex-desktop/update-builder"
    ! grep -F 'codex-update-manager' "$root/usr/share/applications/codex-desktop.desktop"
}

check_provenance() {
    local info="$1"
    test "$(jq -r '.upstreamDmg.sha256 // empty' "$info")" = "$expected_dmg_sha256"
    test "$(jq -r '.source.commit // empty' "$info")" = "$expected_upstream_sha"
}

check_native_payload "$inspect_root/deb"
check_native_payload "$inspect_root/rpm"
check_provenance "$inspect_root/deb/opt/codex-desktop/resources/codex-linux-build-info.json"
check_provenance "$inspect_root/rpm/opt/codex-desktop/resources/codex-linux-build-info.json"

app_root="$inspect_root/appimage/squashfs-root"
test -x "$app_root/AppRun"
test -x "$app_root/opt/codex-desktop/start.sh"
test -x "$app_root/opt/codex-desktop/electron"
test -f "$app_root/opt/codex-desktop/content/webview/index.html"
test -f "$app_root/opt/codex-desktop/resources/codex-linux-build-info.json"
test ! -e "$app_root/usr/bin/codex-update-manager"
test ! -e "$app_root/usr/lib/systemd/user/codex-update-manager.service"
test ! -e "$app_root/usr/share/polkit-1/actions/com.github.ilysenko.codex-desktop-linux.update.policy"
test ! -e "$app_root/opt/codex-desktop/update-builder"
check_provenance "$app_root/opt/codex-desktop/resources/codex-linux-build-info.json"

file "$deb" "$rpm_file" "$appimage"
