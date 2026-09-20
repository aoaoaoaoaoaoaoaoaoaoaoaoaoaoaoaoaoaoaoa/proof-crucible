#!/usr/bin/env bash
set -euo pipefail

readonly ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$ROOT"
export ELAN_HOME="${ELAN_HOME:-$HOME/.local/share/elan}"
case "${XDG_CACHE_HOME:-}" in
  /*) cache_home="$XDG_CACHE_HOME" ;;
  *) cache_home="$HOME/.cache" ;;
esac
export LAKE_CACHE_DIR="${LAKE_CACHE_DIR-$cache_home/lake}"

"$ROOT/.crucible/bin/crucible" doctor
"$ROOT/.crucible/bin/crucible" check
"$ROOT/scripts/share-lake-packages.sh" "$ROOT"
"$ROOT/.crucible/bin/crucible" lean-audit \
  --output .lake/build/crucible/LedgerAudit.lean
lake --wfail build proofs
lake env lean \
  -DwarningAsError=true -DautoImplicit=false -Dpp.unicode.fun=true \
  -Dlinter.docPrime=true -Dlinter.hashCommand=true -Dlinter.oldObtain=true \
  -Dlinter.style.refine=true -Dlinter.style.cdot=true \
  -Dlinter.style.dollarSyntax=true -Dlinter.style.lambdaSyntax=true \
  -Dlinter.style.longFile=1500 -Dlinter.style.longLine=true \
  -Dlinter.style.missingEnd=true -Dlinter.style.setOption=true \
  .lake/build/crucible/LedgerAudit.lean
"$ROOT/.crucible/bin/crucible" render --output _site
