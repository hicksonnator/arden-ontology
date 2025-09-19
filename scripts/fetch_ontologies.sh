#!/usr/bin/env bash
set -euo pipefail

# Create directories
mkdir -p externals externals/subsets externals/derived

echo "=== Fetching External Ontologies for Arden v1.2.0 ==="

# ================================================================
# EXISTING CORE SEMANTIC WEB FOUNDATIONS (keep existing)
# ================================================================
echo "Fetching core semantic web foundations..."

# Pin minimal kernels; the rest will be sliced via ROBOT MIREOT
curl -L -o externals/sosa.ttl        https://www.w3.org/ns/sosa/sosa.ttl
curl -L -o externals/geosparql.rdf   https://schemas.opengis.net/geosparql/1.0/geosparql_vocab_all.rdf
curl -L -o externals/qudt-schema.ttl https://qudt.org/2.1/schema/QUDT-v2.1.ttl
curl -L -o externals/qudt-units.ttl  https://qudt.org/2.1/vocab/VOCAB-UNITS-ALL-v2.1.ttl
curl -L -o externals/skos.rdf        https://www.w3.org/2009/08/skos-reference/skos.rdf
curl -L -o externals/prov.ttl        https://www.w3.org/ns/prov.ttl
curl -L -o externals/dcat.ttl        https://www.w3.org/ns/dcat3.ttl

# ================================================================
# NEW ONTOLOGIES FOR v1.2.0 - Agricultural & Financial Focus
# ================================================================
echo "Fetching new external ontologies for v1.2.0..."

# RDF Data Cube - Statistical data structures
echo "  → RDF Data Cube (QB)"
curl -L -H "Accept: text/turtle" -o externals/qb.ttl http://purl.org/linked-data/cube#

# W3C Time Ontology
echo "  → W3C Time Ontology"
curl -L -H "Accept: application/rdf+xml" -o externals/time.rdf http://www.w3.org/2006/time#

# SDMX Vocabulary (Statistical Data and Metadata Exchange)
echo "  → SDMX Vocabularies"
curl -L -o externals/sdmx-dimension.ttl http://purl.org/linked-data/sdmx/2009/dimension#
curl -L -o externals/sdmx-measure.ttl   http://purl.org/linked-data/sdmx/2009/measure#
curl -L -o externals/sdmx-attribute.ttl http://purl.org/linked-data/sdmx/2009/attribute#

# ================================================================
# LARGE ONTOLOGIES - FULL DOWNLOADS FOR MIREOT EXTRACTION
# ================================================================
echo "Fetching large ontologies for MIREOT extraction..."

# AGRO Agronomy Ontology
echo "  → AGRO (Agronomy Ontology)"
curl -L -o externals/agro-full.owl http://purl.obolibrary.org/obo/agro.owl

# NCBITaxon - NCBI Taxonomy
echo "  → NCBITaxon (NCBI Taxonomy)"
curl -L -o externals/ncbitaxon-full.owl http://purl.obolibrary.org/obo/ncbitaxon.owl

# Crop Ontology - Maize and Soybean
echo "  → Crop Ontology (Maize)"
curl -L -o externals/crop-maize-full.rdf https://cropontology.org/ontology/CO_322/rdf

echo "  → Crop Ontology (Soybean)"
curl -L -o externals/crop-soybean-full.rdf https://cropontology.org/ontology/CO_336/rdf

# FIBO - Financial Industry Business Ontology (selected modules)
echo "  → FIBO (Financial Ontology - selected modules)"
mkdir -p externals/fibo-modules

# FND - Foundations
curl -L -o externals/fibo-modules/fnd-agents.rdf https://spec.edmcouncil.org/fibo/ontology/master/latest/FND/AgentsAndPeople/Agents.rdf
curl -L -o externals/fibo-modules/fnd-parties.rdf https://spec.edmcouncil.org/fibo/ontology/master/latest/FND/Parties/Parties.rdf
curl -L -o externals/fibo-modules/fnd-dates.rdf https://spec.edmcouncil.org/fibo/ontology/master/latest/FND/DatesAndTimes/FinancialDates.rdf
curl -L -o externals/fibo-modules/fnd-currency.rdf https://spec.edmcouncil.org/fibo/ontology/master/latest/FND/Accounting/CurrencyAmount.rdf
curl -L -o externals/fibo-modules/fnd-contracts.rdf https://spec.edmcouncil.org/fibo/ontology/master/latest/FND/Agreements/Contracts.rdf

# BE - Business Entities
curl -L -o externals/fibo-modules/be-legal.rdf https://spec.edmcouncil.org/fibo/ontology/master/latest/BE/LegalEntities/LegalPersons.rdf
curl -L -o externals/fibo-modules/be-corps.rdf https://spec.edmcouncil.org/fibo/ontology/master/latest/BE/LegalEntities/CorporateBodies.rdf

# FBC - Financial Business Core (Debt/Loans only)
curl -L -o externals/fibo-modules/fbc-debt.rdf https://spec.edmcouncil.org/fibo/ontology/master/latest/FBC/DebtAndEquities/Debt.rdf

# ACTUS - Algorithmic Contract Types
echo "  → ACTUS (Contract Types)"
curl -L -o externals/actus-vocabulary.rdf https://spec.edmcouncil.org/fibo/ontology/master/latest/ACTUS/ACTUSControlledVocabulary.rdf
curl -L -o externals/actus-metadata.rdf https://spec.edmcouncil.org/fibo/ontology/master/latest/ACTUS/MetadataACTUS.rdf

# ================================================================
# VERIFICATION AND CHECKSUMS
# ================================================================
echo "Computing SHA256 checksums..."

# Compute checksums for all downloaded files
find externals/ -name "*.ttl" -o -name "*.rdf" -o -name "*.owl" | while read file; do
    sha256sum "$file" >> externals/checksums-$(date +%Y%m%d).txt
done

echo "Fetching complete! Next steps:"
echo "  1. Run ROBOT MIREOT extractions"
echo "  2. Update externals/LOCKFILE.md with new checksums"
echo "  3. Build merged ontology with new externals"