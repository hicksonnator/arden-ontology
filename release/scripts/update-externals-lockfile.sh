#!/bin/bash
"""
Update external ontology dependencies lockfile with real SHA256 checksums.
Run this script periodically to verify external dependencies haven't changed.
"""

set -euo pipefail

LOCKFILE="externals/LOCKFILE.md"
TEMP_DIR=$(mktemp -d)
DATE=$(date +%Y-%m-%d)

echo "🔒 Updating external ontologies lockfile..."
echo "Temp directory: $TEMP_DIR"
echo ""

# Function to download and compute checksum
verify_external() {
    local name="$1"
    local url="$2"
    local expected_pattern="$3"

    echo "📡 Fetching $name..."
    local temp_file="$TEMP_DIR/$name.rdf"

    if curl -s -f "$url" > "$temp_file"; then
        local checksum=$(sha256sum "$temp_file" | cut -d' ' -f1)
        echo "  ✅ Downloaded: $(wc -c < "$temp_file") bytes"
        echo "  🔐 SHA256: $checksum"

        # Update lockfile in-place
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS sed
            sed -i '' "s/$expected_pattern.*/$expected_pattern\`$checksum\`/" "$LOCKFILE"
            sed -i '' "s/Last Verified.*: .*-.*-.*/Last Verified**: $DATE/" "$LOCKFILE"
        else
            # GNU sed
            sed -i "s/$expected_pattern.*/$expected_pattern\`$checksum\`/" "$LOCKFILE"
            sed -i "s/Last Verified.*: .*-.*-.*/Last Verified**: $DATE/" "$LOCKFILE"
        fi

        echo ""
    else
        echo "  ❌ Failed to download $name from $url"
        return 1
    fi
}

# Update each external dependency
verify_external "SOSA" \
    "https://raw.githubusercontent.com/w3c/sdw/gh-pages/ssn/rdf/sosa.ttl" \
    "**SHA256**: "

verify_external "QUDT-Schema" \
    "https://qudt.org/2.1/schema/QUDT-v2.1.ttl" \
    "**SHA256**: "

verify_external "QUDT-Units" \
    "https://qudt.org/2.1/vocab/VOCAB-UNITS-ALL-v2.1.ttl" \
    "**SHA256**: "

verify_external "GeoSPARQL" \
    "https://raw.githubusercontent.com/opengeospatial/ogc-geosparql/master/1.0/geosparql_vocab_all.rdf" \
    "**SHA256**: "

verify_external "DCAT" \
    "https://www.w3.org/ns/dcat.ttl" \
    "**SHA256**: "

verify_external "PROV-O" \
    "https://www.w3.org/ns/prov.ttl" \
    "**SHA256**: "

verify_external "SKOS" \
    "https://www.w3.org/2009/08/skos-reference/skos.rdf" \
    "**SHA256**: "

# Cleanup
rm -rf "$TEMP_DIR"

echo "✅ External ontologies lockfile updated: $LOCKFILE"
echo ""
echo "🔄 Next steps:"
echo "1. Review changes: git diff $LOCKFILE"
echo "2. Commit changes: git add $LOCKFILE && git commit -m 'Update external ontology checksums'"
echo "3. Schedule this script to run nightly in CI/CD pipeline"