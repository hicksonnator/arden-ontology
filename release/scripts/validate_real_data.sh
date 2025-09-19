#!/usr/bin/env bash
set -euo pipefail

echo "=== Validating Real Agricultural Data Against Arden Ontology ==="

# Real data files to validate
REAL_DATA_FILES=(
  "data/nass_yield_2023.ttl"
  "data/rma_sob_2023.ttl"
  "data/census_ers_2023.ttl"
  "data/fips_counties.ttl"
)

# Check if pyshacl is available
if ! command -v pyshacl &> /dev/null; then
    echo "WARNING: pyshacl not found. Install with: pip install pyshacl"
    echo "Continuing with file existence checks only..."
    PYSHACL_AVAILABLE=false
else
    PYSHACL_AVAILABLE=true
fi

echo "1. Checking real data file integrity..."
for file in "${REAL_DATA_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✓ $file exists"
        # Basic RDF syntax check (if you have rapper/riot installed)
        # rapper -q -c "$file" 2>/dev/null && echo "    ✓ Valid RDF syntax" || echo "    ⚠ RDF syntax issues"
    else
        echo "  ✗ $file missing"
    fi
done

if [ "$PYSHACL_AVAILABLE" = true ]; then
    echo ""
    echo "2. Running SHACL validation on real data..."

    echo "  Testing NASS yield data..."
    echo "    L1 (Ingest-safe):"
    pyshacl -s shapes/arden-shapes-l1.ttl -t data/nass_yield_2023.ttl -i rdfs -f human --abort || echo "    L1 validation issues found"

    echo "    L2 (Production):"
    pyshacl -s shapes/arden-shapes-l2.ttl -t data/nass_yield_2023.ttl -i rdfs -f human --abort || echo "    L2 validation issues found"

    echo "    Agricultural constraints:"
    pyshacl -s shapes/arden-shapes-agricultural.ttl -t data/nass_yield_2023.ttl -i rdfs -f human --abort || echo "    Agricultural validation issues found"

    echo ""
    echo "  Testing RMA insurance data..."
    echo "    Provenance constraints:"
    pyshacl -s shapes/arden-shapes-provenance.ttl -t data/rma_sob_2023.ttl -i rdfs -f human --abort || echo "    Provenance validation issues found"

    echo "    Financial constraints:"
    pyshacl -s shapes/arden-shapes-financial.ttl -t data/rma_sob_2023.ttl -i rdfs -f human --abort || echo "    Financial validation issues found"

    echo ""
    echo "  Testing geospatial data..."
    echo "    Geospatial constraints:"
    pyshacl -s shapes/arden-shapes-geospatial.ttl -t data/fips_counties.ttl -i rdfs -f human --abort || echo "    Geospatial validation issues found"

    echo ""
    echo "  Testing cross-domain constraints..."
    echo "    Domain-specific rules:"
    pyshacl -s shapes/arden-shapes-domains.ttl -t data/nass_yield_2023.ttl -i rdfs -f human --abort || echo "    Domain validation issues found"

    echo ""
    echo "  Testing enterprise constraints..."
    echo "    Enterprise rules:"
    pyshacl -s shapes/arden-shapes-enterprise.ttl -t data/census_ers_2023.ttl -i rdfs -f human --abort || echo "    Enterprise validation issues found"

else
    echo ""
    echo "2. Skipping SHACL validation (pyshacl not available)"
fi

echo ""
echo "3. Running real data queries..."

# Check if SPARQL query tool is available
if command -v sparql &> /dev/null; then
    echo "  Testing yield above average query..."
    # Combine all real data files for query
    cat data/nass_yield_2023.ttl data/fips_counties.ttl > /tmp/combined_yield_data.ttl
    sparql --data=/tmp/combined_yield_data.ttl --query=queries/cq-real-yield-above-average.rq --results=TSV | head -10

    echo ""
    echo "  Testing RMA vs actual yield comparison..."
    cat data/nass_yield_2023.ttl data/rma_sob_2023.ttl data/fips_counties.ttl > /tmp/combined_comparison_data.ttl
    sparql --data=/tmp/combined_comparison_data.ttl --query=queries/cq-real-rma-vs-actual.rq --results=TSV | head -5

    echo ""
    echo "  Testing prevented planting analysis..."
    sparql --data=data/rma_sob_2023.ttl --data=data/fips_counties.ttl --query=queries/cq-real-prevented-planting-impact.rq --results=TSV

    # Cleanup
    rm -f /tmp/combined_*.ttl

elif command -v riot &> /dev/null; then
    echo "  SPARQL tool not found, checking basic RDF parsing..."
    for file in "${REAL_DATA_FILES[@]}"; do
        if [ -f "$file" ]; then
            echo "    Parsing $file..."
            riot --quiet "$file" > /dev/null && echo "      ✓ Valid RDF" || echo "      ✗ RDF parsing failed"
        fi
    done
else
    echo "  No SPARQL or RDF tools available for query testing"
fi

echo ""
echo "4. Data quality summary..."

# Count triples in each file (if riot is available)
if command -v riot &> /dev/null; then
    for file in "${REAL_DATA_FILES[@]}"; do
        if [ -f "$file" ]; then
            count=$(riot --quiet --count "$file" 2>/dev/null || echo "unknown")
            echo "  $file: $count triples"
        fi
    done
fi

echo ""
echo "=== Real Data Validation Complete ==="
echo ""
echo "Expected Results:"
echo "  - NASS yield data: 6 Iowa counties with corn yields 185-205 bu/acre"
echo "  - RMA data: Prevented planting events in Polk/Linn counties (spring 2023)"
echo "  - Census data: Population/income data for 4 Iowa counties"
echo "  - FIPS data: 6 Iowa counties with WKT geometries"
echo ""
echo "Next Steps:"
echo "  1. Review any SHACL validation issues above"
echo "  2. Run queries manually with your preferred SPARQL endpoint"
echo "  3. Use this data as a template for your own agricultural datasets"