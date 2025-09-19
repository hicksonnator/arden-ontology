#!/usr/bin/env bash
set -euo pipefail

mkdir -p build/slices release

# Capture build provenance
BUILD_ID="arden-build-$(date +%Y%m%d-%H%M%S)"
GIT_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
BUILD_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "Starting build: $BUILD_ID"
echo "Git commit: $GIT_COMMIT"
echo "Timestamp: $BUILD_TIMESTAMP"

# Example: create minimal slices with ROBOT (add AGRO/ENVO/FIBO slices as you list required terms)
# robot extract --method MIREOT --input externals/qudt.ttl \
#   --lower-terms "http://qudt.org/schema/qudt/QuantityValue" \
#   --output build/slices/qudt-min.ttl

# Merge Arden modules + slices
robot merge \
  --input ontology/arden-app.ttl \
  --input mappings/schema-bridge.ttl \
  --input mappings/codes-bridge.ttl \
  --collapse-import-closure true \
  --output release/arden-merged-v1.1.1.ttl

# Reason (ELK)
robot reason \
  --input release/arden-merged-v1.1.1.ttl \
  --reasoner ELK \
  --output release/arden-inferred-v1.1.1.owl

# SHACL validation (graduated levels + new domain shapes)
echo "Running SHACL validation - Level 1 (ingest-safe)..."
pyshacl -s shapes/arden-shapes-l1.ttl -m -i rdfs -f human -t release/arden-merged-v1.1.1.ttl

echo "Running SHACL validation - Level 2 (production)..."
pyshacl -s shapes/arden-shapes-l2.ttl -m -i rdfs -f human -t release/arden-merged-v1.1.1.ttl

echo "Running SHACL validation - Level 3 (analytics)..."
pyshacl -s shapes/arden-shapes-l3.ttl -m -i rdfs -f human -t release/arden-merged-v1.1.1.ttl

echo "Running domain-specific SHACL validation..."
pyshacl -s shapes/arden-shapes-financial.ttl -m -i rdfs -f human -t release/arden-merged-v1.1.1.ttl
pyshacl -s shapes/arden-shapes-agricultural.ttl -m -i rdfs -f human -t release/arden-merged-v1.1.1.ttl
pyshacl -s shapes/arden-shapes-geospatial.ttl -m -i rdfs -f human -t release/arden-merged-v1.1.1.ttl
pyshacl -s shapes/arden-shapes-provenance.ttl -m -i rdfs -f human -t release/arden-merged-v1.1.1.ttl
pyshacl -s shapes/arden-shapes-crossdomain.ttl -m -i rdfs -f human -t release/arden-merged-v1.1.1.ttl
pyshacl -s shapes/arden-shapes-domains.ttl -m -i rdfs -f human -t release/arden-merged-v1.1.1.ttl
pyshacl -s shapes/arden-shapes-enterprise.ttl -m -i rdfs -f human -t release/arden-merged-v1.1.1.ttl

echo "SHACL validation complete."

# Add build provenance to release
cat > release/arden-build-provenance.ttl << EOF
@prefix : <https://arden.ag/builds/> .
@prefix prov: <http://www.w3.org/ns/prov#> .
@prefix dct: <http://purl.org/dc/terms/> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

:${BUILD_ID} a prov:Activity ;
  prov:startedAtTime "${BUILD_TIMESTAMP}"^^xsd:dateTime ;
  prov:wasAssociatedWith :arden-build-system ;
  dct:identifier "${BUILD_ID}" ;
  <https://example.org/gitCommit> "${GIT_COMMIT}" ;
  prov:generated <file://$(pwd)/release/arden-merged-v1.1.1.ttl> ,
                 <file://$(pwd)/release/arden-inferred-v1.1.1.owl> .

:arden-build-system a prov:SoftwareAgent ;
  rdfs:label "Arden Ontology Build System" .
EOF

echo "Build provenance recorded in release/arden-build-provenance.ttl"