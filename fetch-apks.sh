#!/bin/bash
# SPDX-FileCopyrightText: The PerleOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Downloads the APKs listed in prebuilt/apks.txt into prebuilt/<module>.apk
# and checks each one against its pinned SHA-256. An APK already present with
# the right hash is not downloaded again; a mismatch is an error.
#
# The package manager does not extract native libraries from system apps, so
# the arm64 libraries of the modules in jni_modules are extracted to
# prebuilt/<module>/lib/arm64/ and installed next to the APK by Android.mk.

set -euo pipefail

dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/prebuilt
jni_modules=(GmsCore)
status=0
tmp=
trap 'rm -f "$tmp"' EXIT

fetch() {
    local module=$1 sha256=$2 url=$3
    tmp=$(mktemp --suffix=.apk "$dir/.$module.XXXXXX")
    if curl -fsSL --retry 3 -o "$tmp" "$url" && echo "$sha256  $tmp" | sha256sum -c --status; then
        chmod 644 "$tmp"
        mv "$tmp" "$dir/$module.apk"
        tmp=
        return 0
    fi
    rm -f "$tmp"
    tmp=
    return 1
}

extract_jni() {
    local module=$1 sha256=$2 libdir="$dir/$1/lib/arm64"
    if [ "$(cat "$dir/$module/.sha256" 2>/dev/null)" = "$sha256" ]; then
        return 0
    fi
    rm -rf "${dir:?}/$module"
    mkdir -p "$libdir"
    unzip -q -j "$dir/$module.apk" 'lib/arm64-v8a/*.so' -d "$libdir"
    echo "$sha256" > "$dir/$module/.sha256"
}

while read -r module sha256 url; do
    case "$module" in ''|'#'*) continue ;; esac
    apk="$dir/$module.apk"
    if ! { [ -f "$apk" ] && echo "$sha256  $apk" | sha256sum -c --status; }; then
        echo "vendor/microg: fetching $module"
        # F-Droid moves older versions from repo/ to archive/.
        if ! fetch "$module" "$sha256" "$url" &&
            ! { [[ "$url" == https://f-droid.org/repo/* ]] &&
                fetch "$module" "$sha256" "${url/\/repo\//\/archive\/}"; }; then
            echo "vendor/microg: $module: download failed or SHA-256 mismatch ($url)" >&2
            status=1
            continue
        fi
    fi
    if [[ " ${jni_modules[*]} " == *" $module "* ]]; then
        extract_jni "$module" "$sha256"
    fi
done < "$dir/apks.txt"

exit "$status"
