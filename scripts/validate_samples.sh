#!/usr/bin/env bash
set -euo pipefail

echo "=== Running SHACL Validation on Sample Data ==="

# Check if pyshacl is available
if ! command -v pyshacl &> /dev/null; then
    echo "WARNING: pyshacl not found. Install with: pip install pyshacl"
    echo "Skipping validation tests..."
    exit 0
fi

echo "Testing sample data against SHACL constraints..."

echo "1. Testing parcels against L1 (ingest-safe) constraints..."
pyshacl -s shapes/arden-shapes-l1.ttl -t data/sample_parcel.ttl -i rdfs -f human || echo "L1 validation failed"

echo "2. Testing yields against L2 (production) constraints..."
pyshacl -s shapes/arden-shapes-l2.ttl -t data/sample_yield.ttl -i rdfs -f human || echo "L2 validation failed"

echo "3. Testing model estimates against provenance constraints..."
pyshacl -s shapes/arden-shapes-provenance.ttl -t data/sample_model_estimate.ttl -i rdfs -f human || echo "Provenance validation failed"

echo "4. Testing geospatial constraints on parcels..."
pyshacl -s shapes/arden-shapes-geospatial.ttl -t data/sample_parcel.ttl -i rdfs -f human || echo "Geospatial validation failed"

echo "5. Testing domain-specific constraints..."
pyshacl -s shapes/arden-shapes-domains.ttl -t data/sample_yield.ttl -i rdfs -f human || echo "Domain validation failed"

echo "6. Testing agricultural constraints..."
pyshacl -s shapes/arden-shapes-agricultural.ttl -t data/sample_yield.ttl -i rdfs -f human || echo "Agricultural validation failed"

echo "=== SHACL Validation Complete ==="
echo "Review any validation failures above."
echo "Green bars = production-ready data patterns!"