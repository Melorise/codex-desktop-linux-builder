#!/usr/bin/env bash
set -Eeuo pipefail

upstream_dir="${1:?usage: prepare-upstream.sh UPSTREAM_DIR}"
control="$upstream_dir/packaging/linux/control"
spec="$upstream_dir/packaging/linux/codex-desktop.spec"
package_common="$upstream_dir/scripts/lib/package-common.sh"

for path in "$control" "$spec" "$package_common"; do
    if [ ! -f "$path" ]; then
        echo "Required upstream packaging file is missing: $path" >&2
        exit 1
    fi
done

if ! grep -q 'package_with_updater_enabled' "$package_common"; then
    echo 'Upstream no longer exposes PACKAGE_WITH_UPDATER support.' >&2
    exit 1
fi

python3 - "$control" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
lines = text.splitlines()
depends_indexes = [i for i, line in enumerate(lines) if line.startswith("Depends: ")]
if len(depends_indexes) != 1:
    raise SystemExit(f"expected exactly one Depends line in {path}")

index = depends_indexes[0]
dependencies = [item.strip() for item in lines[index][len("Depends: "):].split(",")]
updater_only_names = {
    "build-essential",
    "dpkg",
    "p7zip-full",
    "pkexec",
    "policykit-1",
    "polkit",
    "polkitd",
    "unzip",
}

def alternative_names(expression: str) -> set[str]:
    return {part.strip().split()[0] for part in expression.split("|")}

filtered = [
    dependency
    for dependency in dependencies
    if alternative_names(dependency).isdisjoint(updater_only_names)
]
removed = len(dependencies) - len(filtered)
if removed < 5:
    raise SystemExit(
        f"upstream DEB dependencies changed unexpectedly; removed only {removed} entries"
    )
for required in ("curl", "python3", "xdg-utils"):
    if required not in filtered:
        raise SystemExit(f"required runtime dependency disappeared: {required}")

lines[index] = "Depends: " + ", ".join(filtered)
path.write_text("\n".join(lines) + ("\n" if text.endswith("\n") else ""))
PY

python3 - "$spec" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text()
pattern = re.compile(
    r"(%if __PACKAGE_WITH_UPDATER__\n"
    r"Requires:[^\n]+\n"
    r"%else\n)"
    r"Requires:[^\n]+"
    r"(\n%endif)"
)
replacement = r"\1Requires:       python3, curl, xdg-utils\2"
updated, count = pattern.subn(replacement, text, count=1)
if count != 1:
    raise SystemExit("upstream RPM updater dependency block changed unexpectedly")
path.write_text(updated)
PY

grep -F 'Depends: ' "$control"
grep -A4 -F '%if __PACKAGE_WITH_UPDATER__' "$spec" | head -5
