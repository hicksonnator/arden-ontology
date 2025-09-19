# Arden Ontology Named Graphs & Access Model

**Version**: 1.2.0
**Last Updated**: 2024-12-19

## Graph Organization Strategy

### Core Principle
Separate concerns using named graphs to enable independent updates, access control, and lifecycle management.

### Graph Hierarchy

```
📊 graph:ontology
├── Core agricultural domain model (READ-ONLY post-deploy)
├── Stable IRIs and class definitions
└── Updated only with version releases

🗺️ graph:mappings
├── Units normalization (QUDT canonical forms)
├── Code schemes (FIPS, NASS, Census variables)
├── External mappings (AGROVOC, DBpedia)
└── Updated quarterly or as external sources change

🔍 graph:shapes
├── SHACL validation rules (L1, L2, L3 tiers)
├── Domain-specific constraints
└── Updated with ontology releases

📈 graph:data:real:{source}{year}
├── graph:data:real:nass2024     → USDA NASS crop data
├── graph:data:real:rma2024      → RMA insurance/loss data
├── graph:data:real:census2024   → ACS socioeconomic data
├── graph:data:real:cdl2024      → USDA CDL land cover
└── One graph per source-year for efficient querying

📋 graph:views
├── Materialized county/year aggregates
├── Pre-computed analytics for dashboards
├── Rebuilt nightly from source graphs
└── Read-only for analysts

🚨 graph:quarantine
├── Data that failed validation
├── Manual review queue
└── Archived monthly after review
```

## Access Control Matrix

| Graph | Public Read | Analyst Read | ETL Write | Admin Write | Admin Delete |
|-------|-------------|--------------|-----------|-------------|--------------|
| **ontology** | ✅ | ✅ | ❌ | data-arch only | data-arch only |
| **mappings** | ✅ | ✅ | ❌ | data-arch only | data-arch only |
| **shapes** | ✅ | ✅ | ❌ | data-arch only | data-arch only |
| **data:real:\*** | ✅ | ✅ | etl-service | ops team | ops team |
| **views** | ✅ | ✅ | etl-service | ops team | ops team |
| **quarantine** | ❌ | ✅ | etl-service | ops team | ops team |

### Role Definitions

**Public**: Anonymous users, web applications
- Can query stable ontology and public datasets
- Cannot see quarantined or sensitive data

**Analyst**: Data scientists, researchers, business users
- Full read access to validated data
- Can inspect quarantine for data quality research
- Cannot modify any graphs

**ETL Service**: Automated data ingestion service
- Can write to data and quarantine graphs
- Cannot modify ontology, mappings, or shapes
- Uses service account with rotating credentials

**Data Architecture Team**: Ontology stewards
- Full control over ontology, mappings, shapes
- Can promote/demote data between graphs
- Approves all schema changes

**Operations Team**: Platform administrators
- Can manage data graphs and infrastructure
- Cannot modify ontological definitions
- Handles backup, recovery, performance tuning

## Graph Lifecycle Management

### Ontology Releases (Major/Minor)
```bash
# 1. Development in feature branch
git checkout -b feature/crop-phenology-extension

# 2. Update ontology modules
vi ontology/arden-crops.ttl

# 3. Test compatibility
bash scripts/build.sh
bash scripts/validate_samples.sh

# 4. PR with mandatory reviews
git push origin feature/crop-phenology-extension
# → Requires data-arch approval + automated tests

# 5. Release deployment
git tag v1.3.0
./scripts/release-package.sh
# → Loads into graph:ontology with versioned backup
```

### Data Source Updates (Continuous)
```bash
# 1. Daily NASS ingest
python scripts/csv_to_rdf_template.py \
  raw/nass_daily_${DATE}.csv \
  staged/nass_${DATE}.ttl

# 2. Batch validation
pyshacl -s shapes/arden-shapes-l1.ttl staged/nass_${DATE}.ttl

# 3. Conditional loading
if [ $? -eq 0 ]; then
  # Load to current year graph
  load_to_graph "graph:data:real:nass2024" staged/nass_${DATE}.ttl
else
  # Quarantine for review
  load_to_graph "graph:quarantine" staged/nass_${DATE}.ttl
  alert_data_team "NASS batch validation failed: ${DATE}"
fi
```

### Materialized Views Refresh
```sparql
# Nightly aggregation (example)
PREFIX arden: <https://arden.ag/ont/core#>
PREFIX arden-ag: <https://arden.ag/ont/ag#>
PREFIX sosa: <http://www.w3.org/ns/sosa/>

# Clear previous views
DROP GRAPH <graph:views> ;

# Rebuild county/year aggregates
INSERT {
  GRAPH <graph:views> {
    ?county_year a arden:CountyYearSummary ;
                 arden:county ?county ;
                 arden:year ?year ;
                 arden-ag:avgCornYield ?avg_yield ;
                 arden-ag:totalAcres ?total_acres ;
                 dct:created ?now .
  }
}
WHERE {
  GRAPH <graph:data:real:nass2024> {
    ?obs a arden-ag:YieldObservation ;
         sosa:hasFeatureOfInterest ?parcel ;
         sosa:resultTime ?time ;
         sosa:hasResult ?result .

    ?parcel arden:locatedInCounty ?county .
    ?result qudt:numericValue ?yield_value ;
            qudt:unit unit:BushelPerAcre .

    BIND(YEAR(?time) AS ?year)
    BIND(NOW() AS ?now)
  }
}
GROUP BY ?county ?year
```

## Security & Privacy Controls

### Sensitive Data Handling
```turtle
# Example: Farmer identity anonymization
<https://arden.ag/data/farmer/hash_abc123> a arden:Farmer ;
  arden:sourceSystemId "FARMER_HASH_abc123" ;  # Original SSN hashed
  arden:operatesParcel <https://arden.ag/data/parcel/42> ;
  # No PII stored in RDF
```

### Query Access Patterns
```sparql
# Public queries: Aggregated data only
SELECT ?county ?avg_yield WHERE {
  GRAPH <graph:views> {
    ?summary arden:county ?county ;
             arden-ag:avgCornYield ?avg_yield .
  }
} ORDER BY DESC(?avg_yield)

# Analyst queries: Individual observations OK
SELECT ?parcel ?yield ?date WHERE {
  GRAPH <graph:data:real:nass2024> {
    ?obs sosa:hasFeatureOfInterest ?parcel ;
         sosa:hasResult ?result ;
         sosa:resultTime ?date .
    ?result qudt:numericValue ?yield .
  }
} LIMIT 1000

# Admin queries: Full provenance access
SELECT ?obs ?source_file ?ingest_time WHERE {
  GRAPH <graph:data:real:nass2024> {
    ?obs prov:wasGeneratedBy ?activity .
    ?activity prov:used ?source_file ;
              prov:endedAtTime ?ingest_time .
  }
}
```

## Performance Optimization

### Graph-Specific Indexes
```sparql
# Text search on labels and identifiers
PREFIX luc: <http://www.ontotext.com/owlim/lucene#>
INSERT DATA {
  GRAPH <graph:indexes> {
    luc:ontologyIndex luc:createConnector "rdfs:label" .
    luc:ontologyIndex luc:createConnector "arden:sourceSystemId" .
  }
}

# Geospatial index on parcel boundaries
PREFIX geo: <http://www.ontotext.com/owlim/geo#>
INSERT DATA {
  GRAPH <graph:indexes> {
    geo:spatialIndex geo:createConnector "geosparql:asWKT" .
  }
}

# Temporal index on observation times
PREFIX time: <http://www.ontotext.com/owlim/temporal#>
INSERT DATA {
  GRAPH <graph:indexes> {
    time:temporalIndex time:createConnector "sosa:resultTime" .
  }
}
```

### Query Hints for Multi-Graph Operations
```sparql
# Efficient cross-graph join pattern
SELECT ?parcel ?yield ?county_name WHERE {
  GRAPH <graph:data:real:nass2024> {
    ?obs sosa:hasFeatureOfInterest ?parcel ;
         sosa:hasResult ?result .
    ?result qudt:numericValue ?yield .
  }

  GRAPH <graph:ontology> {
    ?parcel arden:locatedInCounty ?county .
  }

  GRAPH <graph:mappings> {
    ?county skos:prefLabel ?county_name .
  }
}
# Hint: Join on ?parcel first (most selective)
```

## Backup & Recovery Strategy

### Graph-Level Backups
```bash
# Daily incremental backups by graph
for graph in ontology mappings shapes data:real:nass2024 views quarantine; do
  backup_timestamp=$(date +%Y%m%d-%H%M%S)

  # Export graph to turtle
  curl -X POST "http://sparql-endpoint/export" \
    -H "Accept: text/turtle" \
    -d "CONSTRUCT { ?s ?p ?o } WHERE { GRAPH <graph:${graph}> { ?s ?p ?o } }" \
    > backups/graph_${graph//[:\/]/_}_${backup_timestamp}.ttl

  # Compress and upload to blob storage
  gzip backups/graph_${graph//[:\/]/_}_${backup_timestamp}.ttl
  aws s3 cp backups/graph_${graph//[:\/]/_}_${backup_timestamp}.ttl.gz \
    s3://arden-backups/graphs/
done
```

### Point-in-Time Recovery
```bash
# Restore specific graph to previous state
restore_graph_to_timestamp() {
  local graph_name="$1"
  local restore_timestamp="$2"

  # Clear current graph
  curl -X POST "http://sparql-endpoint/update" \
    -d "DROP GRAPH <graph:${graph_name}>"

  # Restore from backup
  aws s3 cp s3://arden-backups/graphs/graph_${graph_name}_${restore_timestamp}.ttl.gz \
    - | gunzip | \
  curl -X POST "http://sparql-endpoint/statements?context=graph:${graph_name}" \
    -H "Content-Type: text/turtle" \
    --data-binary @-
}

# Example: Restore NASS data to yesterday
restore_graph_to_timestamp "data:real:nass2024" "20241218-060000"
```

## Monitoring & Alerting

### Graph Health Metrics
```bash
# Monitor graph sizes and update frequencies
monitor_graphs() {
  for graph in ontology mappings shapes data:real:nass2024 views quarantine; do
    triple_count=$(curl -s "http://sparql-endpoint/query" \
      -d "SELECT (COUNT(*) AS ?count) WHERE { GRAPH <graph:${graph}> { ?s ?p ?o } }")

    last_update=$(curl -s "http://sparql-endpoint/query" \
      -d "SELECT (MAX(?modified) AS ?last) WHERE {
           GRAPH <graph:${graph}> { ?s dct:modified ?modified }
         }")

    echo "${graph}: ${triple_count} triples, last updated ${last_update}"

    # Alert if critical graphs haven't been updated recently
    if [[ "$graph" == "data:real:"* ]] && [[ "$last_update" < $(date -d "2 days ago" -I) ]]; then
      echo "ALERT: ${graph} hasn't been updated in >48 hours" | \
        mail -s "Arden Data Staleness Alert" ops@company.com
    fi
  done
}
```

### Access Audit Logging
```sparql
# Log all write operations with provenance
INSERT DATA {
  GRAPH <graph:audit> {
    <urn:audit:$(uuidgen)> a prov:Activity ;
                           prov:wasAssociatedWith <user:${USER}> ;
                           prov:startedAtTime "$(date -u +%Y-%m-%dT%H:%M:%SZ)"^^xsd:dateTime ;
                           prov:used <graph:${TARGET_GRAPH}> ;
                           rdfs:comment "${OPERATION_DESCRIPTION}" .
  }
}
```

This named graphs strategy provides the foundation for enterprise-scale ontology management while maintaining data integrity, performance, and governance controls.