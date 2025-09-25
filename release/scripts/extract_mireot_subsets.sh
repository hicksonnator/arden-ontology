#!/usr/bin/env bash
set -euo pipefail

# ================================================================
# ROBOT MIREOT Extraction Script for Arden Ontology v1.2.0
# ================================================================
#
# This script extracts minimal subsets from large external ontologies
# using ROBOT's MIREOT functionality. Each subset is limited to
# target term counts to keep the merged ontology lightweight.
#
# Prerequisites:
# - ROBOT tool installed and available in PATH
# - External ontology full downloads completed
# - MIREOT term lists created in mireot/ directory
# ================================================================

echo "=== ROBOT MIREOT Extraction for Arden v1.2.0 ==="

# Check if ROBOT is available
if ! command -v robot >/dev/null 2>&1; then
    echo "❌ ROBOT tool not found. Please install ROBOT and add to PATH."
    echo "   Download from: https://github.com/ontodev/robot/releases"
    exit 1
fi

echo "✅ ROBOT found: $(robot --version)"

# Create output directory
mkdir -p externals/subsets

# ================================================================
# AGRO AGRONOMY ONTOLOGY - Target: ≤500 terms
# ================================================================
echo "🌾 Extracting AGRO (Agronomy Ontology) subset..."

if [ -f "externals/agro-full.owl" ] && [ -f "mireot/agro_terms.txt" ]; then
    robot extract \
        --input externals/agro-full.owl \
        --method BOT \
        --term-file mireot/agro_terms.txt \
        --output externals/subsets/agro_subset.owl

    echo "  → AGRO subset extracted to externals/subsets/agro_subset.owl"
else
    echo "  ⚠️  AGRO files missing, skipping extraction"
fi

# ================================================================
# CROP ONTOLOGY - MAIZE - Target: ≤100 terms
# ================================================================
echo "🌽 Extracting Crop Ontology (Maize) subset..."

if [ -f "externals/crop-maize-full.rdf" ] && [ -f "mireot/crop_ontology_maize_terms.txt" ]; then
    robot extract \
        --input externals/crop-maize-full.rdf \
        --method BOT \
        --term-file mireot/crop_ontology_maize_terms.txt \
        --output externals/subsets/crop_maize_subset.owl

    echo "  → Maize subset extracted to externals/subsets/crop_maize_subset.owl"
else
    echo "  ⚠️  Maize CO files missing, skipping extraction"
fi

# ================================================================
# CROP ONTOLOGY - SOYBEAN - Target: ≤100 terms
# ================================================================
echo "🫘 Extracting Crop Ontology (Soybean) subset..."

if [ -f "externals/crop-soybean-full.rdf" ] && [ -f "mireot/crop_ontology_soybean_terms.txt" ]; then
    robot extract \
        --input externals/crop-soybean-full.rdf \
        --method BOT \
        --term-file mireot/crop_ontology_soybean_terms.txt \
        --output externals/subsets/crop_soybean_subset.owl

    echo "  → Soybean subset extracted to externals/subsets/crop_soybean_subset.owl"
else
    echo "  ⚠️  Soybean CO files missing, skipping extraction"
fi

# ================================================================
# NCBITAXON - Target: ≤50 terms
# ================================================================
echo "🦠 Extracting NCBITaxon subset..."

if [ -f "externals/ncbitaxon-full.owl" ] && [ -f "mireot/ncbitaxon_terms.txt" ]; then
    robot extract \
        --input externals/ncbitaxon-full.owl \
        --method BOT \
        --term-file mireot/ncbitaxon_terms.txt \
        --output externals/subsets/ncbitaxon_subset.owl

    echo "  → NCBITaxon subset extracted to externals/subsets/ncbitaxon_subset.owl"
else
    echo "  ⚠️  NCBITaxon files missing, skipping extraction"
fi

# ================================================================
# FIBO - FINANCIAL ONTOLOGY - Target: ≤300 terms
# ================================================================
echo "💰 Extracting FIBO (Financial Ontology) subset..."

if [ -d "externals/fibo-modules" ] && [ -f "mireot/fibo_terms.txt" ]; then
    # Merge FIBO modules first
    robot merge \
        --input externals/fibo-modules/fnd-agents.rdf \
        --input externals/fibo-modules/fnd-parties.rdf \
        --input externals/fibo-modules/fnd-dates.rdf \
        --input externals/fibo-modules/fnd-currency.rdf \
        --input externals/fibo-modules/fnd-contracts.rdf \
        --input externals/fibo-modules/be-legal.rdf \
        --input externals/fibo-modules/be-corps.rdf \
        --input externals/fibo-modules/fbc-debt.rdf \
        --output externals/fibo-merged.owl

    # Extract subset from merged FIBO
    robot extract \
        --input externals/fibo-merged.owl \
        --method BOT \
        --term-file mireot/fibo_terms.txt \
        --output externals/subsets/fibo_subset.owl

    echo "  → FIBO subset extracted to externals/subsets/fibo_subset.owl"
else
    echo "  ⚠️  FIBO files missing, skipping extraction"
fi

# ================================================================
# ACTUS - CONTRACT TYPES - Target: ~30 terms
# ================================================================
echo "📋 Extracting ACTUS (Contract Types) subset..."

if [ -f "externals/actus-vocabulary.rdf" ] && [ -f "mireot/actus_terms.txt" ]; then
    robot extract \
        --input externals/actus-vocabulary.rdf \
        --method BOT \
        --term-file mireot/actus_terms.txt \
        --output externals/subsets/actus_subset.owl

    echo "  → ACTUS subset extracted to externals/subsets/actus_subset.owl"
else
    echo "  ⚠️  ACTUS files missing, skipping extraction"
fi

# ================================================================
# VALIDATION AND SUMMARY
# ================================================================
echo "📊 Subset Extraction Summary:"

for subset in externals/subsets/*.owl; do
    if [ -f "$subset" ]; then
        # Count triples using robot query
        count=$(robot query \
            --input "$subset" \
            --query <(echo "SELECT (COUNT(*) AS ?count) WHERE { ?s ?p ?o }") \
            --format TSV | tail -n 1)

        filename=$(basename "$subset")
        echo "  • $filename: $count triples"
    fi
done

echo "✅ MIREOT extraction complete!"
echo ""
echo "Next steps:"
echo "  1. Update externals/LOCKFILE.md with subset checksums"
echo "  2. Create bridge mappings in mappings/"
echo "  3. Update build scripts to include subsets"