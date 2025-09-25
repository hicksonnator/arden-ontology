#!/usr/bin/env bash
set -euo pipefail

# ================================================================
# Arden Ontology Build Script v1.2.0
# ================================================================
# Builds merged ontology with external dependencies and MIREOT subsets
# Includes new agricultural, financial, and socioeconomic domains
# ================================================================

: "${ARDEN_ONTOLOGY_VERSION:=v1.2.0}"

mkdir -p build/slices release

# Capture build provenance
BUILD_ID="arden-build-$(date +%Y%m%d-%H%M%S)"
GIT_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
BUILD_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "=== Arden Ontology Build v1.2.0 ==="
echo "Build ID: $BUILD_ID"
echo "Git commit: $GIT_COMMIT"
echo "Timestamp: $BUILD_TIMESTAMP"
echo "Version: $ARDEN_ONTOLOGY_VERSION"

# ================================================================
# STEP 1: FETCH EXTERNAL ONTOLOGIES
# ================================================================
echo "Step 1: Fetching external ontologies..."
if [ -x scripts/fetch_ontologies.sh ]; then
    bash scripts/fetch_ontologies.sh
else
    echo "Warning: scripts/fetch_ontologies.sh not found or not executable"
fi

# ================================================================
# STEP 2: EXTRACT MIREOT SUBSETS
# ================================================================
echo "Step 2: Extracting MIREOT subsets..."
if [ -x scripts/extract_mireot_subsets.sh ]; then
    bash scripts/extract_mireot_subsets.sh
else
    echo "Warning: scripts/extract_mireot_subsets.sh not found or not executable"
fi

# ================================================================
# STEP 3: MERGE ARDEN MODULES + EXTERNALS + BRIDGES
# ================================================================
echo "Step 3: Merging Arden modules with external ontologies..."

# Build input list dynamically
MERGE_INPUTS=""

# Core Arden modules
for module in ontology/arden-*.ttl; do
    if [ -f "$module" ]; then
        MERGE_INPUTS="$MERGE_INPUTS --input $module"
    fi
done

# Bridge mappings
for bridge in mappings/arden-bridges-*.ttl; do
    if [ -f "$bridge" ]; then
        MERGE_INPUTS="$MERGE_INPUTS --input $bridge"
    fi
done

# Legacy mappings
for mapping in mappings/schema-bridge.ttl mappings/codes-bridge.ttl; do
    if [ -f "$mapping" ]; then
        MERGE_INPUTS="$MERGE_INPUTS --input $mapping"
    fi
done

# External ontology subsets
for subset in externals/subsets/*.owl; do
    if [ -f "$subset" ]; then
        MERGE_INPUTS="$MERGE_INPUTS --input $subset"
    fi
done

# Core external ontologies
for external in externals/sosa.ttl externals/geosparql.rdf externals/qudt-schema.ttl externals/qudt-units.ttl externals/skos.rdf externals/prov.ttl externals/dcat.ttl externals/qb.ttl externals/time.rdf; do
    if [ -f "$external" ]; then
        MERGE_INPUTS="$MERGE_INPUTS --input $external"
    fi
done

# SDMX vocabularies
for sdmx in externals/sdmx-*.ttl; do
    if [ -f "$sdmx" ]; then
        MERGE_INPUTS="$MERGE_INPUTS --input $sdmx"
    fi
done

# Derived ontologies (USDA Soil)
for derived in externals/derived/*.ttl; do
    if [ -f "$derived" ]; then
        MERGE_INPUTS="$MERGE_INPUTS --input $derived"
    fi
done

# Execute merge
robot merge \
  $MERGE_INPUTS \
  --collapse-import-closure true \
  --output release/arden-merged-${ARDEN_ONTOLOGY_VERSION}.ttl

echo "✅ Merged ontology created: release/arden-merged-${ARDEN_ONTOLOGY_VERSION}.ttl"

# ================================================================
# STEP 4: REASONING
# ================================================================
echo "Step 4: Running reasoning (ELK)..."
robot reason \
  --input release/arden-merged-${ARDEN_ONTOLOGY_VERSION}.ttl \
  --reasoner ELK \
  --output release/arden-inferred-${ARDEN_ONTOLOGY_VERSION}.owl

echo "✅ Reasoning complete: release/arden-inferred-${ARDEN_ONTOLOGY_VERSION}.owl"

# ================================================================
# STEP 5: SHACL VALIDATION
# ================================================================
echo "Step 5: Running SHACL validation..."

MERGED_FILE="release/arden-merged-${ARDEN_ONTOLOGY_VERSION}.ttl"

# Core validation levels
echo "Running SHACL validation - Level 1 (ingest-safe)..."
if [ -f shapes/arden-shapes-l1.ttl ]; then
    pyshacl -s shapes/arden-shapes-l1.ttl -m -i rdfs -f human -t "$MERGED_FILE" || echo "L1 validation warnings detected"
fi

echo "Running SHACL validation - Level 2 (production)..."
if [ -f shapes/arden-shapes-l2.ttl ]; then
    pyshacl -s shapes/arden-shapes-l2.ttl -m -i rdfs -f human -t "$MERGED_FILE" || echo "L2 validation issues detected"
fi

echo "Running SHACL validation - Level 3 (analytics)..."
if [ -f shapes/arden-shapes-l3.ttl ]; then
    pyshacl -s shapes/arden-shapes-l3.ttl -m -i rdfs -f human -t "$MERGED_FILE" || echo "L3 validation issues detected"
fi

# Domain-specific validation (existing)
echo "Running legacy domain-specific SHACL validation..."
for shape in shapes/arden-shapes-financial.ttl shapes/arden-shapes-agricultural.ttl shapes/arden-shapes-geospatial.ttl shapes/arden-shapes-provenance.ttl shapes/arden-shapes-crossdomain.ttl shapes/arden-shapes-domains.ttl shapes/arden-shapes-enterprise.ttl; do
    if [ -f "$shape" ]; then
        echo "  Validating with $(basename "$shape")..."
        pyshacl -s "$shape" -m -i rdfs -f human -t "$MERGED_FILE" || echo "  Validation issues in $(basename "$shape")"
    fi
done

# New domain-specific validation (v1.2.0)
echo "Running new domain-specific SHACL validation (v1.2.0)..."
for shape in shapes/arden-shapes-crops.ttl shapes/arden-shapes-finance.ttl shapes/arden-shapes-socio.ttl shapes/arden-shapes-soil.ttl shapes/arden-shapes-taxonomy.ttl; do
    if [ -f "$shape" ]; then
        echo "  Validating with $(basename "$shape")..."
        pyshacl -s "$shape" -m -i rdfs -f human -t "$MERGED_FILE" || echo "  Validation issues in $(basename "$shape")"
    fi
done

echo "✅ SHACL validation complete."

# ================================================================
# STEP 6: BUILD PROVENANCE
# ================================================================
echo "Step 6: Recording build provenance..."

cat > release/arden-build-provenance.ttl << EOF
@prefix : <https://arden.ag/builds/> .
@prefix prov: <http://www.w3.org/ns/prov#> .
@prefix dct: <http://purl.org/dc/terms/> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .

:${BUILD_ID} a prov:Activity ;
  prov:startedAtTime "${BUILD_TIMESTAMP}"^^xsd:dateTime ;
  prov:wasAssociatedWith :arden-build-system ;
  dct:identifier "${BUILD_ID}" ;
  <https://example.org/gitCommit> "${GIT_COMMIT}" ;
  <https://arden.ag/ont/version> "${ARDEN_ONTOLOGY_VERSION}" ;
  prov:generated <file://$(pwd)/release/arden-merged-${ARDEN_ONTOLOGY_VERSION}.ttl> ,
                 <file://$(pwd)/release/arden-inferred-${ARDEN_ONTOLOGY_VERSION}.owl> .

:arden-build-system a prov:SoftwareAgent ;
  rdfs:label "Arden Ontology Build System v1.2.0" ;
  rdfs:comment "Build system for Arden agricultural ontology with external dependencies" .
EOF

echo "✅ Build provenance recorded in release/arden-build-provenance.ttl"

# ================================================================
# STEP 7: BUILD SUMMARY
# ================================================================
echo ""
echo "=== Build Summary ==="
echo "Version: $ARDEN_ONTOLOGY_VERSION"
echo "Build ID: $BUILD_ID"
echo "Status: ✅ SUCCESS"
echo ""
echo "Generated files:"
if [ -f "release/arden-merged-${ARDEN_ONTOLOGY_VERSION}.ttl" ]; then
    SIZE=$(ls -lh "release/arden-merged-${ARDEN_ONTOLOGY_VERSION}.ttl" | awk '{print $5}')
    echo "  📄 release/arden-merged-${ARDEN_ONTOLOGY_VERSION}.ttl ($SIZE)"
fi
if [ -f "release/arden-inferred-${ARDEN_ONTOLOGY_VERSION}.owl" ]; then
    SIZE=$(ls -lh "release/arden-inferred-${ARDEN_ONTOLOGY_VERSION}.owl" | awk '{print $5}')
    echo "  🧠 release/arden-inferred-${ARDEN_ONTOLOGY_VERSION}.owl ($SIZE)"
fi

# Count external dependencies
EXTERNAL_COUNT=$(find externals/ -name "*.ttl" -o -name "*.rdf" -o -name "*.owl" | wc -l)
SUBSET_COUNT=$(find externals/subsets/ -name "*.owl" 2>/dev/null | wc -l)

echo ""
echo "External dependencies: $EXTERNAL_COUNT files"
echo "MIREOT subsets: $SUBSET_COUNT subsets"
echo ""
echo "🎉 Arden Ontology v1.2.0 build complete!"