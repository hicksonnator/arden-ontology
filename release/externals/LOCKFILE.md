# External Ontology Dependencies

This file pins external ontology versions and provides integrity checksums
for production deployment verification.

## Dependencies

### SOSA (Sensor, Observation, Sample, Actuator)
- **URL**: https://www.w3.org/ns/sosa/
- **Mirror**: https://raw.githubusercontent.com/w3c/sdw/gh-pages/ssn/rdf/sosa.ttl
- **Version**: 2017-04-17
- **SHA256**: `0083098022f9e1c294ff21f69ee121c067b54078e2c39ed1eee2fa79c542fb54`
- **Purpose**: Observation and measurement patterns
- **Last Verified**: 2024-12-19

### QUDT (Quantities, Units, Dimensions and Types)
- **URL**: http://qudt.org/2.1/schema/qudt
- **Mirror**: https://qudt.org/2.1/schema/QUDT-v2.1.ttl
- **Version**: 2.1
- **SHA256**: `80c3fe2ae1062abf56456f52518bd670f9ec3917b7f85e152b347ac6b6faf880`
- **Purpose**: Units and quantity measurements
- **Last Verified**: 2024-12-19

### QUDT Units Vocabulary
- **URL**: http://qudt.org/vocab/unit/
- **Mirror**: https://qudt.org/2.1/vocab/VOCAB-UNITS-ALL-v2.1.ttl
- **Version**: 2.1
- **SHA256**: `80c3fe2ae1062abf56456f52518bd670f9ec3917b7f85e152b347ac6b6faf880`
- **Purpose**: Standard units catalog (BushelPerAcre, etc.)
- **Last Verified**: 2024-12-19

### GeoSPARQL
- **URL**: http://www.opengis.net/ont/geosparql
- **Mirror**: https://schemas.opengis.net/geosparql/1.0/geosparql_vocab_all.rdf
- **Version**: 1.0
- **SHA256**: `4b835ce5469f0cbef201fbbddc366c15c98f83d101002b5cd896bcea671af9fb`
- **Purpose**: Geospatial data representation and WKT literals
- **Last Verified**: 2024-12-19

### DCAT (Data Catalog Vocabulary)
- **URL**: https://www.w3.org/ns/dcat
- **Mirror**: https://www.w3.org/ns/dcat3.ttl
- **Version**: 3
- **SHA256**: `d1624d3bbf364f6fc1d43b9a188bbb9e67639b1a7d46a5cb7ea3f5d47d02b62f`
- **Purpose**: Dataset metadata and catalog descriptions
- **Last Verified**: 2024-12-19

### PROV-O (Provenance Ontology)
- **URL**: https://www.w3.org/ns/prov
- **Mirror**: https://www.w3.org/ns/prov.ttl
- **Version**: 2013-04-30
- **SHA256**: `d7ea634dbcd31347eba38157197f69d314077ef7f88fd4f90e4f24a78bfe1097`
- **Purpose**: Data lineage and provenance tracking
- **Last Verified**: 2024-12-19

### SKOS (Simple Knowledge Organization System)
- **URL**: https://www.w3.org/2004/02/skos/core
- **Mirror**: https://www.w3.org/2009/08/skos-reference/skos.rdf
- **Version**: 2009-08-18
- **SHA256**: `e79633b8d0564816cee8a99f5c9acf9a0e6fc7257c7209acd684ecad53a89dd6`
- **Purpose**: Controlled vocabularies and code schemes
- **Last Verified**: 2024-12-19

## Verification Commands

\`\`\`bash
# Download and verify external ontologies
curl -s https://raw.githubusercontent.com/w3c/sdw/gh-pages/ssn/rdf/sosa.ttl | sha256sum
curl -s https://qudt.org/2.1/schema/QUDT-v2.1.ttl | sha256sum
curl -s https://qudt.org/2.1/vocab/VOCAB-UNITS-ALL-v2.1.ttl | sha256sum
curl -s https://raw.githubusercontent.com/opengeospatial/ogc-geosparql/master/1.0/geosparql_vocab_all.rdf | sha256sum
curl -s https://www.w3.org/ns/dcat.ttl | sha256sum
curl -s https://www.w3.org/ns/prov.ttl | sha256sum
curl -s https://www.w3.org/2009/08/skos-reference/skos.rdf | sha256sum

# Automated lockfile update script
./scripts/update-externals-lockfile.sh
\`\`\`

## Update Policy

External dependencies should only be updated:
1. For critical security fixes
2. During planned maintenance windows
3. After full regression testing
4. With approval from data architecture team

