#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq
# shellcheck shell=bash

set -euo pipefail

readonly NPINS_VERSION="0.3.1"
npins_version_string=$(npins --version)

if [[ ! "${npins_version_string}" == *"${NPINS_VERSION}" ]]; then
    printf "Required 'npins %s', found '%s'\n" \
           "${NPINS_VERSION}" \
           "${npins_version_string}" >&2
    printf "Run from project's 'nix-shell' to ensure versions match!\n" >&2
    exit 1
fi

if npins --lock-file npins.json update; then
    readarray -t nixpkgs <<< "$(jq -r '.pins."nixos-unstable" | .revision, .hash' npins.json)"
    revision="${nixpkgs[0]}"
    sri_hash=$(nix-hash --to-sri --type sha256 "${nixpkgs[1]}")
    jq --arg jq_rev "${revision}" --arg jq_hash "${sri_hash}" \
       '.nodes.nixpkgs.locked.rev |= $jq_rev | .nodes.nixpkgs.locked.narHash |= $jq_hash' \
       flake.lock > flake.lock.tmp
    mv flake.lock.tmp flake.lock
fi
