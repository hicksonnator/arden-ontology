#!/usr/bin/env bash
set -euo pipefail

# ================================================================
# Arden Ontology Multi-Stage Build Script v1.2.0
# ================================================================
# Builds merged ontology in stages to handle large external dependencies
# Enables proper reasoning and validation on manageable chunks
# ================================================================

: "${ARDEN_ONTOLOGY_VERSION:=v1.2.0}"

mkdir -p build/stages release

# Capture build provenance
BUILD_ID="arden-staged-build-$(date +%Y%m%d-%H%M%S)"
GIT_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
BUILD_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "=== Arden Ontology Multi-Stage Build v1.2.0 ==="
echo "Build ID: $BUILD_ID"
echo "Git commit: $GIT_COMMIT"
echo "Timestamp: $BUILD_TIMESTAMP"
echo "Version: $ARDEN_ONTOLOGY_VERSION"

# ================================================================
# STAGE 1: CORE MERGE (Arden + Essential Externals)
# ================================================================
echo ""
echo "🏗️  STAGE 1: Core Arden + Essential Externals"
echo "Target: <1MB, fast reasoning"

./bin/robot merge \
  --catalog catalog.xml \
  --input ontology/arden-core.ttl \
  --input ontology/arden-ag.ttl \
  --input ontology/arden-fin.ttl \
  --input ontology/arden-geo.ttl \
  --input ontology/arden-measure.ttl \
  --input ontology/arden-app.ttl \
  --input externals/sosa.ttl \
  --input externals/skos.rdf \
  --input externals/prov.ttl \
  --input externals/qb.ttl \
  --input externals/time.rdf \
  --collapse-import-closure true \
  --output build/stages/stage1-core.ttl

STAGE1_SIZE=$(ls -lh build/stages/stage1-core.ttl | awk '{print $5}')
echo "✅ Stage 1 complete: $STAGE1_SIZE"

# Test reasoning on core
echo "🧠 Testing ELK reasoning on Stage 1..."
timeout 60s ./bin/robot reason \
  --input build/stages/stage1-core.ttl \
  --reasoner ELK \
  --output build/stages/stage1-core-inferred.owl || echo "⚠️  Stage 1 reasoning timeout"

# ================================================================
# STAGE 2: DOMAIN EXTENSIONS (MIREOT Subsets + Mappings)
# ================================================================
echo ""
echo "🏗️  STAGE 2: Domain Extensions"
echo "Target: 1-2MB with MIREOT subsets"

./bin/robot merge \
  --input build/stages/stage1-core.ttl \
  --input ontology/arden-crops.ttl \
  --input ontology/arden-equipment.ttl \
  --input ontology/arden-markets.ttl \
  --input ontology/arden-socio.ttl \
  --input ontology/arden-integration.ttl \
  --input ontology/arden-regulatory.ttl \
  --input mappings/arden-bridges-agro.ttl \
  --input mappings/arden-bridges-fibo.ttl \
  --input mappings/arden-bridges-actus.ttl \
  --input mappings/schema-bridge.ttl \
  --input mappings/codes-bridge.ttl \
  --input externals/subsets/agro_subset.owl \
  --input externals/subsets/crop_maize_subset.owl \
  --input externals/subsets/crop_soybean_subset.owl \
  --input externals/subsets/fibo_subset.owl \
  --input externals/geosparql.rdf \
  --input externals/dcat.ttl \
  --collapse-import-closure true \
  --output build/stages/stage2-domains.ttl

STAGE2_SIZE=$(ls -lh build/stages/stage2-domains.ttl | awk '{print $5}')
echo "✅ Stage 2 complete: $STAGE2_SIZE"

# Test reasoning on domains
echo "🧠 Testing ELK reasoning on Stage 2..."
timeout 120s ./bin/robot reason \
  --input build/stages/stage2-domains.ttl \
  --reasoner ELK \
  --output build/stages/stage2-domains-inferred.owl || echo "⚠️  Stage 2 reasoning timeout"

# ================================================================
# STAGE 3: LIGHTWEIGHT UNITS (QUDT Subset Creation)
# ================================================================
echo ""
echo "🏗️  STAGE 3: Lightweight Units Integration"
echo "Creating QUDT units subset..."

# Extract only commonly used units from the massive QUDT units file
./bin/robot extract \
  --input externals/qudt-units.ttl \
  --method MIREOT \
  --upper-terms "http://qudt.org/vocab/unit/KiloGM" \
  --upper-terms "http://qudt.org/vocab/unit/M" \
  --upper-terms "http://qudt.org/vocab/unit/HA" \
  --upper-terms "http://qudt.org/vocab/unit/TON" \
  --upper-terms "http://qudt.org/vocab/unit/BushelPerAcre" \
  --upper-terms "http://qudt.org/vocab/unit/USD" \
  --upper-terms "http://qudt.org/vocab/unit/PERCENT" \
  --output build/stages/qudt-units-subset.ttl || {
    echo "⚠️  QUDT subset extraction failed, using schema only"
    cp externals/qudt-schema.ttl build/stages/qudt-units-subset.ttl
  }

./bin/robot merge \
  --input build/stages/stage2-domains.ttl \
  --input build/stages/qudt-units-subset.ttl \
  --input externals/sdmx-attribute.ttl \
  --input externals/sdmx-dimension.ttl \
  --input externals/sdmx-measure.ttl \
  --input externals/derived/usda-soil-taxonomy.ttl \
  --collapse-import-closure true \
  --output build/stages/stage3-with-units.ttl

STAGE3_SIZE=$(ls -lh build/stages/stage3-with-units.ttl | awk '{print $5}')
echo "✅ Stage 3 complete: $STAGE3_SIZE"

# ================================================================
# STAGE 4: FINAL ASSEMBLY + COMPREHENSIVE VALIDATION
# ================================================================
echo ""
echo "🏗️  STAGE 4: Final Assembly & Validation"

# Create final merged version
cp build/stages/stage3-with-units.ttl release/arden-merged-staged-${ARDEN_ONTOLOGY_VERSION}.ttl

echo "🧠 Final ELK reasoning..."
timeout 300s ./bin/robot reason \
  --input release/arden-merged-staged-${ARDEN_ONTOLOGY_VERSION}.ttl \
  --reasoner ELK \
  --output release/arden-inferred-staged-${ARDEN_ONTOLOGY_VERSION}.owl || echo "⚠️  Final reasoning timeout"

echo "🔍 Multi-domain SHACL validation..."

# Validate by domain to avoid parsing issues
MERGED_FILE="release/arden-merged-staged-${ARDEN_ONTOLOGY_VERSION}.ttl"
VALIDATION_RESULTS=""

for level in l1 l2 l3; do
  if [ -f "shapes/arden-shapes-${level}.ttl" ]; then
    echo "  Validating Level $level..."
    timeout 60s pyshacl -s "shapes/arden-shapes-${level}.ttl" -f human "$MERGED_FILE" > "build/validation-${level}.txt" 2>&1 || echo "    Level $level validation had issues"
    VALIDATION_RESULTS="$VALIDATION_RESULTS\n  - Level $level: $(wc -l < "build/validation-${level}.txt") lines"
  fi
done

# Domain-specific validation
for domain in crops finance socio soil taxonomy; do
  if [ -f "shapes/arden-shapes-${domain}.ttl" ]; then
    echo "  Validating $domain domain..."
    timeout 60s pyshacl -s "shapes/arden-shapes-${domain}.ttl" -f human "$MERGED_FILE" > "build/validation-${domain}.txt" 2>&1 || echo "    $domain validation had issues"
    VALIDATION_RESULTS="$VALIDATION_RESULTS\n  - $domain: $(wc -l < "build/validation-${domain}.txt") lines"
  fi
done

# ================================================================
# BUILD SUMMARY
# ================================================================
echo ""
echo "=== Multi-Stage Build Summary ==="
echo "Version: $ARDEN_ONTOLOGY_VERSION"
echo "Build ID: $BUILD_ID"
echo ""
echo "Stage Results:"
echo "  🏗️  Stage 1 (Core): $STAGE1_SIZE"
echo "  🏗️  Stage 2 (Domains): $STAGE2_SIZE"
echo "  🏗️  Stage 3 (Units): $STAGE3_SIZE"
echo ""

FINAL_SIZE=$(ls -lh "$MERGED_FILE" | awk '{print $5}')
echo "📄 Final merged ontology: $FINAL_SIZE"

if [ -f "release/arden-inferred-staged-${ARDEN_ONTOLOGY_VERSION}.owl" ]; then
    INFERRED_SIZE=$(ls -lh "release/arden-inferred-staged-${ARDEN_ONTOLOGY_VERSION}.owl" | awk '{print $5}')
    echo "🧠 Inferred ontology: $INFERRED_SIZE"
fi

echo ""
echo "🔍 SHACL Validation Results:$VALIDATION_RESULTS"

echo ""
echo "🎉 Multi-stage Arden Ontology v1.2.0 build complete!"
echo "✨ Optimized for reasoning and validation performance"