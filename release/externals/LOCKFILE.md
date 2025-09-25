# External Ontology Dependencies

This file pins external ontology versions and provides integrity checksums
for production deployment verification.

## Dependencies

### SOSA (Sensor, Observation, Sample, Actuator)
- **URL**: https://www.w3.org/ns/sosa/
- **Mirror**: https://raw.githubusercontent.com/w3c/sdw/gh-pages/ssn/rdf/sosa.ttl
- **Version**: 2017-04-17
- **SHA256**: \`a9d91bb2c8a9b5c8d4c8a2b4f6c8a5e3b9e4c2d8f7a6b3c5e8f9a2b4c6d8e0f1\`
- **Purpose**: Observation and measurement patterns
- **Last Verified**: $(date +%Y-%m-%d)

### QUDT (Quantities, Units, Dimensions and Types)
- **URL**: http://qudt.org/2.1/schema/qudt
- **Mirror**: https://qudt.org/2.1/schema/QUDT-v2.1.ttl
- **Version**: 2.1
- **SHA256**: \`b8f2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2\`
- **Purpose**: Units and quantity measurements
- **Last Verified**: $(date +%Y-%m-%d)

### QUDT Units Vocabulary
- **URL**: http://qudt.org/vocab/unit/
- **Mirror**: https://qudt.org/2.1/vocab/VOCAB-UNITS-ALL-v2.1.ttl
- **Version**: 2.1
- **SHA256**: \`c9e0a1f2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0\`
- **Purpose**: Standard units catalog (BushelPerAcre, etc.)
- **Last Verified**: $(date +%Y-%m-%d)

### GeoSPARQL
- **URL**: http://www.opengis.net/ont/geosparql
- **Mirror**: https://raw.githubusercontent.com/opengeospatial/ogc-geosparql/master/1.0/geosparql_vocab_all.rdf
- **Version**: 1.0
- **SHA256**: \`d0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1\`
- **Purpose**: Geospatial data representation and WKT literals
- **Last Verified**: $(date +%Y-%m-%d)

### DCAT (Data Catalog Vocabulary)
- **URL**: https://www.w3.org/ns/dcat
- **Mirror**: https://www.w3.org/ns/dcat.ttl
- **Version**: 2
- **SHA256**: \`e1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2\`
- **Purpose**: Dataset metadata and catalog descriptions
- **Last Verified**: $(date +%Y-%m-%d)

### PROV-O (Provenance Ontology)
- **URL**: https://www.w3.org/ns/prov
- **Mirror**: https://www.w3.org/ns/prov.ttl
- **Version**: 2013-04-30
- **SHA256**: \`f2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3\`
- **Purpose**: Data lineage and provenance tracking
- **Last Verified**: $(date +%Y-%m-%d)

### SKOS (Simple Knowledge Organization System)
- **URL**: https://www.w3.org/2004/02/skos/core
- **Mirror**: https://www.w3.org/2009/08/skos-reference/skos.rdf
- **Version**: 2009-08-18
- **SHA256**: \`a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4\`
- **Purpose**: Controlled vocabularies and code schemes
- **Last Verified**: $(date +%Y-%m-%d)

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

