# Arden Ontology Production Rollout Guide

This guide takes you from "production-tight" to "production-proven" with concrete validation steps and deployment patterns.

## Quick Start: Hello World to Production

### 1. Test Sample Data (Smoke Test)

```bash
# Run the complete validation pipeline
bash scripts/test_load_order.sh
bash scripts/validate_samples.sh

# Test probe queries
# (Use your SPARQL endpoint or Jena ARQ/RDF4J)
sparql --data=data/sample_yield.ttl --query=queries/probe-simple-yield.rq
```

**Expected Result**: 3 yield observations from sample data, all with valid timestamps and units.

### 2. CSV Ingest Template

Convert your CSV data to RDF:

```bash
# Using Python template
python scripts/csv_to_rdf_template.py data/sample_yield.csv output.ttl

# Using SPARQL INSERT (in your ETL pipeline)
# Load scripts/sparql_insert_template.rq and bind variables from CSV
```

### 3. SHACL Validation Gates

Run validation at each ETL stage:

```bash
# L1: Ingest-safe (basic structure)
pyshacl -s shapes/arden-shapes-l1.ttl -t your_data.ttl -i rdfs -f human

# L2: Production (business rules)
pyshacl -s shapes/arden-shapes-l2.ttl -t your_data.ttl -i rdfs -f human

# Domain-specific constraints
pyshacl -s shapes/arden-shapes-agricultural.ttl -t your_data.ttl -i rdfs -f human
```

**Validation Thresholds for Production**:
- **Green**: All L1 + L2 constraints pass
- **Yellow**: L1 passes, L2 warnings only (proceed with monitoring)
- **Red**: L1 violations (block deployment)

## Production Deployment Pattern

### Phase 1: Build & Tag

```bash
# 1. Fetch foundations
bash scripts/fetch_ontologies.sh

# 2. Build merged ontology with reasoning
make build

# 3. Run full SHACL validation suite
# (This happens automatically in build.sh)

# 4. Tag release if validation passes
git tag v1.2.0
```

### Phase 2: Staging Validation

1. **Load Test Data Slice**
   ```bash
   # Load ontology + mappings + small real dataset
   # Example: 1 county of NASS yield data + RMA SoB sample
   ```

2. **Run Health Dashboard**
   ```sparql
   # Execute queries/probe-health-dashboard.rq
   # Verify key counts and quality metrics
   ```

3. **Competency Query Validation**
   ```bash
   # Test your domain queries return meaningful results
   sparql --query=queries/cq-ag-01-yield-above-county.rq
   sparql --query=queries/cq-equipment-01-tractor-operations-2024.rq
   sparql --query=queries/cq-regulatory-01-water-rights-expiring.rq
   ```

### Phase 3: Production Deployment

#### Load Order (Critical)
```bash
# 1. Base ontology (arden-merged-v1.1.1.ttl)
# 2. Mappings (schema-bridge.ttl, codes-bridge.ttl)
# 3. External code lists (NASS crops, Census variables)
# 4. Your data (in batches by year/state)
```

#### Batch Processing Pattern
```bash
for batch in data/batches/*.ttl; do
    echo "Processing $batch..."

    # Load to staging graph
    load_to_graph "staging" "$batch"

    # Validate batch
    pyshacl -s shapes/arden-shapes-enterprise.ttl -t "$batch" -f human

    # If validation passes, promote to production
    if [ $? -eq 0 ]; then
        promote_to_production "$batch"
    else
        echo "Validation failed for $batch - investigate"
    fi
done
```

#### Health Monitoring
Create a dashboard with these SPARQL queries:

```sparql
# 1. Entity counts by class
SELECT ?class (COUNT(?entity) AS ?count) WHERE {
    ?entity a ?class .
    FILTER(?class IN (arden:FarmParcel, arden-ag:YieldObservation, arden-fin:ModeledEstimate))
} GROUP BY ?class

# 2. Data quality metrics
SELECT
    (COUNT(?parcel) AS ?totalParcels)
    (COUNT(?parcelNoGeom) AS ?parcelsWithoutGeometry)
    ((?parcelsWithoutGeometry / ?totalParcels) * 100 AS ?missingGeometryPercent)
WHERE {
    ?parcel a arden:FarmParcel .
    OPTIONAL {
        ?parcelNoGeom a arden:FarmParcel .
        FILTER NOT EXISTS { ?parcelNoGeom geosparql:hasGeometry ?geom }
    }
}

# 3. Recent data freshness
SELECT (MAX(?time) AS ?latestObservation) WHERE {
    ?obs sosa:resultTime ?time .
}
```

**Production Thresholds**:
- Parcels without geometry: < 5%
- ModeledEstimates without model reference: 0%
- Yield observations with invalid units: 0%
- Data freshness: < 24 hours old

## ETL Integration Patterns

### Apache Kafka Streaming
```python
# Kafka consumer → SPARQL INSERT pattern
from kafka import KafkaConsumer
import rdflib

consumer = KafkaConsumer('agricultural-data')
graph = rdflib.Graph()

for message in consumer:
    # Parse JSON message
    data = json.loads(message.value)

    # Use SPARQL INSERT template
    insert_query = load_sparql_template(data)
    graph.update(insert_query)

    # Batch commit every 1000 records
    if len(graph) > 1000:
        commit_to_triplestore(graph)
        graph = rdflib.Graph()
```

### NASS API Integration
```python
# Example: Fetch NASS QuickStats and convert to Arden RDF
import requests
from rdflib import Graph, Namespace

NASS_API = "https://quickstats.nass.usda.gov/api"
ARDEN_AG = Namespace("https://arden.ag/ont/ag#")

def fetch_nass_yields(state_fips, year):
    params = {
        'key': NASS_API_KEY,
        'source_desc': 'SURVEY',
        'sector_desc': 'CROPS',
        'commodity_desc': 'CORN',
        'statisticcat_desc': 'YIELD',
        'state_fips_code': state_fips,
        'year': year
    }

    response = requests.get(f"{NASS_API}/api_GET", params=params)

    # Convert to Arden RDF using templates
    return convert_nass_to_arden_rdf(response.json())
```

## Governance Guardrails

### Mapping Policy
- **Default**: Use `skos:closeMatch` for external vocabularies
- **Upgrade to `skos:exactMatch`**: Requires review + documentation
- **Never use `owl:equivalentClass`**: Unless definitions are identical

### Versioning Strategy
```bash
# Pin external ontologies per release
echo "SOSA 2023-12-01" > externals/LOCKFILE.md
echo "QUDT 2.1.32" >> externals/LOCKFILE.md
echo "GEOSPARQL 1.1" >> externals/LOCKFILE.md

# Verify checksums
sha256sum externals/*.ttl >> externals/LOCKFILE.md
```

### Reasoning Profile
- **CI/Staging**: ELK reasoner (fast, scalable)
- **Release QA**: HermiT (complete, slower)
- **Production**: ELK + pre-computed inferences

## Troubleshooting

### Common Issues

1. **SHACL Validation Failures**
   ```bash
   # Check specific constraint violations
   pyshacl -s shapes/arden-shapes-l1.ttl -t problem_data.ttl -f human -v

   # Focus on high-priority violations first
   grep "Violation" validation_report.txt
   ```

2. **Performance Issues**
   ```bash
   # Check for expensive queries
   EXPLAIN SPARQL SELECT * WHERE { ?s ?p ?o }we 

   # Add indexes on frequently queried properties
   CREATE INDEX ON parcels(county_fips);
   ```

3. **Data Quality Issues**
   ```bash
   # Run health dashboard queries
   sparql --query=queries/probe-health-dashboard.rq

   # Check for orphaned references
   SELECT ?obs WHERE {
       ?obs sosa:hasFeatureOfInterest ?parcel .
       FILTER NOT EXISTS { ?parcel a arden:FarmParcel }
   }
   ```

## Success Metrics

**Week 1**: Sample data loads and validates successfully
**Week 2**: Real data slice (1 state, 1 year) processes without errors
**Month 1**: Full production dataset loaded with <5% quality issues
**Month 3**: Health dashboard shows stable data quality metrics

---

**Next Steps**: Ready for real public test data? I can create legal NASS/RMA samples that fit your shapes and demonstrate the full pipeline with non-toy data.