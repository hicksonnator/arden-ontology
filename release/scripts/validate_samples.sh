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

echo "1. Testing real NASS data against L1 (ingest-safe) constraints..."
if pyshacl -s shapes/arden-shapes-l1.ttl data/nass_yield_2023.ttl -f human; then
    echo "✅ L1 validation PASSED"
else
    echo "❌ L1 validation FAILED"
fi

echo "2. Testing real NASS data against L2 (production) constraints..."
if pyshacl -s shapes/arden-shapes-l2.ttl data/nass_yield_2023.ttl -f human; then
    echo "✅ L2 validation PASSED"
else
    echo "❌ L2 validation FAILED"
fi

echo "3. Testing county data against geospatial constraints..."
if pyshacl -s shapes/arden-shapes-geospatial.ttl data/fips_counties.ttl -f human; then
    echo "✅ Geospatial validation PASSED"
else
    echo "❌ Geospatial validation FAILED"
fi

echo "4. Testing RMA data against financial constraints..."
if pyshacl -s shapes/arden-shapes-l2.ttl data/rma_policies_2023.ttl -f human; then
    echo "✅ Financial validation PASSED"
else
    echo "❌ Financial validation FAILED"
fi

echo "5. Testing enhanced v1.2.1 validation suite..."
if pyshacl sample_data/enhanced-test-data.ttl -s shapes/arden-shapes-enhanced-v1.2.1.ttl -f human; then
    echo "⚠️ Enhanced validation PASSED (no quality issues detected)"
else
    echo "✅ Enhanced validation WORKING (detected quality issues as expected)"
fi

echo "=== SHACL Validation Complete ==="
echo "Review any validation failures above."
echo "Green bars = production-ready data patterns!"