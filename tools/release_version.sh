#!/bin/bash
# Prints the version this build publishes. A pushed tag like v1.1.0 publishes 1.1.0; every other build is
# project.yml's MARKETING_VERSION plus the run number (1.0 -> 1.0.7), so each release is newer than the last.
set -euo pipefail
cd "$(dirname "$0")/.."
base="$(sed -nE 's/^[[:space:]]*MARKETING_VERSION:[[:space:]]*"?([0-9][0-9.]*)"?.*$/\1/p' project.yml | head -n 1)"
if [[ "${GITHUB_REF:-}" == refs/tags/v* ]]; then
  version="${GITHUB_REF_NAME#v}"
else
  version="${base}.${GITHUB_RUN_NUMBER:-0}"
fi
if ! [[ "$version" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
  echo "version '$version' is not dotted-numeric (project.yml says '$base', ref is ${GITHUB_REF:-none})" >&2
  exit 1
fi
echo "$version"
