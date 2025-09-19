#!/usr/bin/env bash
set -euo pipefail

# Config
: "${ARDEN_ONTOLOGY_VERSION:=v1.2.0}"
: "${ARDEN_ONTOLOGY_PATH:=/ontology}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
pass(){ echo -e "${GREEN}✅ $*${NC}"; }
warn(){ echo -e "${YELLOW}⚠️  $*${NC}"; }
fail(){ echo -e "${RED}❌ $*${NC}"; exit 2; }

echo "=== Arden New Externals Test ==="
echo "Version: $ARDEN_ONTOLOGY_VERSION"
echo "Path:    $ARDEN_ONTOLOGY_PATH"
echo

# 1) Fetch externals (idempotent)
if [ -x scripts/fetch_ontologies.sh ]; then
  bash scripts/fetch_ontologies.sh || fail "fetch_ontologies.sh failed"
  pass "Fetched externals"
else
  fail "scripts/fetch_ontologies.sh not found or not executable"
fi

# 2) Build merged ontology
if [ -x scripts/build.sh ]; then
  bash scripts/build.sh || fail "build.sh failed"
  pass "Build completed"
else
  fail "scripts/build.sh not found or not executable"
fi

# 3) Verify externals presence and linkage
if [ -x scripts/verify_externals.sh ]; then
  export ARDEN_ONTOLOGY_VERSION ARDEN_ONTOLOGY_PATH
  bash scripts/verify_externals.sh || fail "verify_externals.sh failed"
  pass "Externals verified"
else
  warn "scripts/verify_externals.sh missing; skipping deep externals checks"
fi

# 4) Run SHACL over representative sample files (if present)
SHAPES_DIR="$ARDEN_ONTOLOGY_PATH/shapes"
if command -v pyshacl >/dev/null 2>&1; then
  found_any=false
  for t in data/sample_yield.ttl data/nass_yield_2023.ttl data/census_ers_2023.ttl data/rma_sob_2023.ttl; do
    if [ -f "$t" ]; then
      found_any=true
      echo "— SHACL L1 on $t"
      pyshacl -s "$SHAPES_DIR/arden-shapes-l1.ttl" -t "$t" -i rdfs -f human || fail "SHACL L1 failed for $t"
      echo "— SHACL L2 on $t"
      pyshacl -s "$SHAPES_DIR/arden-shapes-l2.ttl" -t "$t" -i rdfs -f human || fail "SHACL L2 failed for $t"
    fi
  done
  if [ "$found_any" = false ]; then
    warn "No sample data files found for SHACL. Skipping."
  else
    pass "SHACL validation passed on available samples"
  fi
else
  warn "pyshacl not installed; skipping SHACL runs"
fi

# 5) Probe queries (optional)
if [ -f queries/probe-health-dashboard.rq ]; then
  python - <<'PY' || echo "Skipping rdflib probe (rdflib missing?)"
import os, sys
try:
  import rdflib
except Exception as e:
  print("rdflib missing:", e); sys.exit(0)
g=rdflib.Graph()
merged=os.path.join(os.environ.get("ARDEN_ONTOLOGY_PATH","/ontology"),"release","arden-merged-"+os.environ.get("ARDEN_ONTOLOGY_VERSION","v1.2.0")+".ttl")
for f in [merged, "data/nass_yield_2023.ttl", "data/census_ers_2023.ttl", "data/rma_sob_2023.ttl"]:
  if os.path.exists(f): g.parse(f)
q=open("queries/probe-health-dashboard.rq").read()
for row in g.query(q):
  print(row)
PY
  pass "Health probe ran"
else
  warn "queries/probe-health-dashboard.rq not found; skipping probe"
fi

echo
pass "New externals build + validation completed"