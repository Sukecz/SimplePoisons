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

for toc in SimplePoisons.toc SimplePoisons_TBC.toc SimplePoisons_Camelot.toc; do
    while IFS= read -r toc_file; do
        source_file="${toc_file//\\//}"
        [[ -f "$source_file" ]]
    done < <(sed -n '/^[^#[:space:]].*\.lua$/p' "$toc")
done

diff -u \
    <(sed -n '/^[^#[:space:]].*\.lua$/p' SimplePoisons.toc) \
    <(sed -n '/^[^#[:space:]].*\.lua$/p' SimplePoisons_TBC.toc)
diff -u \
    <(sed -n '/^[^#[:space:]].*\.lua$/p' SimplePoisons.toc) \
    <(sed -n '/^[^#[:space:]].*\.lua$/p' SimplePoisons_Camelot.toc)

grep -qx '## Interface: 11509' SimplePoisons.toc
grep -qx '## Interface: 20506' SimplePoisons_TBC.toc
grep -qx '## Interface: 16001' SimplePoisons_Camelot.toc
grep -qx '## Version: 0.2.0' SimplePoisons.toc
grep -qx '## Version: 0.2.0' SimplePoisons_TBC.toc
grep -qx '## Version: 0.2.0' SimplePoisons_Camelot.toc
grep -qx '## X-Curse-Project-ID: 1660559' SimplePoisons.toc
grep -qx '## X-Curse-Project-ID: 1660559' SimplePoisons_TBC.toc
grep -qx '## X-Curse-Project-ID: 1660559' SimplePoisons_Camelot.toc
grep -qx '## SavedVariablesPerCharacter: SimplePoisonsDB' SimplePoisons.toc
grep -qx '## SavedVariablesPerCharacter: SimplePoisonsDB' SimplePoisons_TBC.toc
grep -qx '## SavedVariablesPerCharacter: SimplePoisonsDB' SimplePoisons_Camelot.toc
grep -qx '## X-Flavor: Vanilla' SimplePoisons.toc
grep -qx '## X-Flavor: TBC' SimplePoisons_TBC.toc
grep -qx '## X-Flavor: Forever' SimplePoisons_Camelot.toc
grep -qx '## AllowLoadGameType: tbc' SimplePoisons_TBC.toc
grep -qx '## AllowLoadGameType: camelot' SimplePoisons_Camelot.toc
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
test -f LICENSE
test -f .github/workflows/ci.yml
test -f .github/workflows/release.yml
# GitHub Actions expression must remain literal here.
# shellcheck disable=SC2016
grep -Fq 'CF_API_KEY: ${{ secrets.CF_API_TOKEN }}' .github/workflows/release.yml
grep -Fq 'uses: R41z0r/packager@7635232c5a62ae46908d9e82b8be0575d6d4d5d3' .github/workflows/release.yml
if rg -n -F '9187' PoisonData.lua; then
    echo "Elixir of Greater Agility must not be offered as a poison." >&2
    exit 1
fi
for expected in 21835 21927 22053 22054 22055 2640 2641 2642 2643 2644; do
    if ! rg -q "(^|[^0-9])$expected([^0-9]|$)" PoisonData.lua; then
        echo "Missing TBC poison data ID: $expected" >&2
        exit 1
    fi
done
if rg -n -F 'lastAppliedFamily' Buttons.lua; then
    echo "The displayed poison must not change until the weapon enchant actually changes." >&2
    exit 1
fi

echo "All SimplePoisons Lua 5.1, behavior, and TOC checks passed."
