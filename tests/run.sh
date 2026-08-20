#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

lua_bin="${LUA_BIN:-$(command -v lua5.1 || command -v lua)}"
luac_bin="${LUAC_BIN:-$(command -v luac5.1 || command -v luac)}"

mapfile -t lua_files < <(find . -type f -name '*.lua' -not -path './.git/*' -print | sort)
for file in "${lua_files[@]}"; do
    "$luac_bin" -p "$file"
done

for test_file in tests/test_*.lua; do
    "$lua_bin" "$test_file"
done

vanilla_files="$(sed -n '/^[^#[:space:]].*\.lua$/p' SimplePoisons.toc)"

while IFS= read -r toc_file; do
    source_file="${toc_file//\\//}"
    [[ -f "$source_file" ]]
done <<< "$vanilla_files"

grep -qx '## Interface: 11509' SimplePoisons.toc
grep -qx '## Version: 0.1.0-alpha.1' SimplePoisons.toc
grep -qx '## X-Curse-Project-ID: 1660559' SimplePoisons.toc
grep -qx '## SavedVariablesPerCharacter: SimplePoisonsDB' SimplePoisons.toc
grep -qx '## X-Flavor: Vanilla' SimplePoisons.toc
grep -Fqx '## IconTexture: Interface\AddOns\SimplePoisons\assets\minimap-icon.tga' SimplePoisons.toc
grep -Fq '_G.SLASH_SIMPLEPOISONS2 = "/sp"' SlashCommands.lua
obsolete_slash="/p""p"
if rg -n -F "$obsolete_slash" .; then
    echo "Obsolete short slash command is still referenced." >&2
    exit 1
fi
file assets/minimap-icon.tga | grep -Fq '256 x 256 x 32'
test -f assets/logo-wide.png
file assets/logo-wide-ui.tga | grep -Fq '512 x 288 x 24'
test -f assets/logo-1-1.png
# PowerShell variables must remain literal here.
# shellcheck disable=SC2016
grep -Fq '"$Server`:$ProjectRoot/assets"' tools/windows/Deploy-WoW-Addons.ps1
test -f LICENSE
test -f .github/workflows/ci.yml
test -f .github/workflows/release.yml
# GitHub Actions expression must remain literal here.
# shellcheck disable=SC2016
grep -Fq 'CF_API_KEY: ${{ secrets.CF_API_TOKEN }}' .github/workflows/release.yml
grep -Fq 'uses: BigWigsMods/packager@v2' .github/workflows/release.yml

echo "All SimplePoisons Lua 5.1, behavior, and TOC checks passed."
