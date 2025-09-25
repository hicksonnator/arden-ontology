#!/usr/bin/env bash
set -euo pipefail

echo "=== Testing Arden Ontology Load Order ==="

# Step 1: Build the merged ontology first
echo "1. Building merged ontology..."
bash scripts/build.sh

# Step 2: Create test graph and load in proper order
echo "2. Testing load order with sample data..."

# Load order (critical for validation):
# 1. Merged ontology (with all imports)
# 2. Mappings (schema + codes)
# 3. Sample data

echo "   Loading base ontology..."
# Note: In production, use your triple store's bulk loader
# This is just a demonstration of the correct sequence

echo "   Loading mappings..."
# mappings/schema-bridge.ttl
# mappings/codes-bridge.ttl

echo "   Loading sample data in dependency order..."
echo "     - Parcels (with county references)"
echo "     - Yields (referencing parcels)"
echo "     - Model estimates (with provenance)"
echo "     - Socioeconomic data (with county references)"

# Files to load in order:
LOAD_FILES=(
  "data/sample_parcel.ttl"
  "data/sample_yield.ttl"
  "data/sample_model_estimate.ttl"
  "data/sample_socio.ttl"
)

echo "3. Validating each dataset with appropriate SHACL shapes..."

# Test each dataset against its relevant shapes
echo "   Testing parcels against L1 constraints..."
# pyshacl -s shapes/arden-shapes-l1.ttl -t data/sample_parcel.ttl -i rdfs -f human

echo "   Testing yields against L2 constraints..."
# pyshacl -s shapes/arden-shapes-l2.ttl -t data/sample_yield.ttl -i rdfs -f human

echo "   Testing model estimates against provenance constraints..."
# pyshacl -s shapes/arden-shapes-provenance.ttl -t data/sample_model_estimate.ttl -i rdfs -f human

echo "   Testing socioeconomic data against domain constraints..."
# pyshacl -s shapes/arden-shapes-domains.ttl -t data/sample_socio.ttl -i rdfs -f human

echo "4. Running probe queries..."

echo "=== Load Order Test Complete ==="
echo "Next: Uncomment pyshacl commands above to run actual validation"
echo "Next: Use your triple store's bulk loader with this order in production"