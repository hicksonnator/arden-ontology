# Arden Ontology Production Runbook

**Version**: 1.2.0
**Last Updated**: 2024-12-19
**Next Review**: 2025-03-19

## Quick Start Deployment

### Prerequisites Checklist
- [ ] RDF triple store (Blazegraph, Stardog, or GraphDB) with GeoSPARQL support
- [ ] SPARQL endpoint configured and accessible
- [ ] Build tools: `bash`, `python3`, `rdflib`, `pyshacl`
- [ ] Network access to external ontology mirrors
- [ ] Backup storage and recovery procedures

### 1. Build & Validate Locally

```bash
# Clone and setup
git clone <your-repo> && cd arden-ontology
git checkout v1.2.0

# Environment setup
python3 -m venv .venv && source .venv/bin/activate
pip install rdflib pyshacl

# Build validation pipeline
bash scripts/build.sh

# Validate sample data
bash scripts/validate_samples.sh

# Validate real agricultural data
bash scripts/validate_real_data.sh

# Run health checks
python3 -c "
import rdflib
g = rdflib.Graph()
g.parse('release/arden-merged.ttl')
result = g.query(open('queries/probe-health-dashboard.rq').read())
for row in result:
    if 'FAIL' in str(row):
        print(f'❌ HEALTH CHECK FAILED: {row}')
        exit(1)
print('✅ All health checks passed')
"
```

### 2. Stage Load (Triple Store)

```bash
# Create staging repository
curl -X POST "http://your-sparql-endpoint/repositories" \
  -H "Content-Type: application/json" \
  -d '{"id": "arden-stage", "type": "owlim:MonitorRepository"}'

# Load core ontology into graph:ontology
curl -X POST "http://your-sparql-endpoint/arden-stage/statements?context=graph:ontology" \
  -H "Content-Type: text/turtle" \
  --data-binary @release/ontology/arden-core.ttl

# Load all ontology modules
for f in release/ontology/*.ttl; do
  echo "Loading $(basename $f)..."
  curl -X POST "http://your-sparql-endpoint/arden-stage/statements?context=graph:ontology" \
    -H "Content-Type: text/turtle" \
    --data-binary @"$f"
done

# Load mappings and code schemes into graph:mappings
for f in release/mappings/*.ttl; do
  curl -X POST "http://your-sparql-endpoint/arden-stage/statements?context=graph:mappings" \
    -H "Content-Type: text/turtle" \
    --data-binary @"$f"
done

# Load SHACL shapes into graph:shapes
for f in release/shapes/*.ttl; do
  curl -X POST "http://your-sparql-endpoint/arden-stage/statements?context=graph:shapes" \
    -H "Content-Type: text/turtle" \
    --data-binary @"$f"
done

# Load sample data with provenance
curl -X POST "http://your-sparql-endpoint/arden-stage/statements?context=graph:data:samples" \
  -H "Content-Type: text/turtle" \
  --data-binary @release/data/nass_yield_2023.ttl
```

### 3. In-Store SHACL Validation

```bash
# Run SHACL validation (GraphDB example)
curl -X POST "http://your-sparql-endpoint/arden-stage" \
  -H "Content-Type: application/sparql-query" \
  -d "
PREFIX sh: <http://www.w3.org/ns/shacl#>
SELECT ?focusNode ?resultMessage ?resultPath ?sourceShape WHERE {
  GRAPH <graph:shapes> { ?shape a sh:NodeShape }
  GRAPH <graph:data:samples> {
    ?report a sh:ValidationReport ;
            sh:result ?result .
    ?result sh:focusNode ?focusNode ;
            sh:resultMessage ?resultMessage ;
            sh:resultPath ?resultPath ;
            sh:sourceShape ?sourceShape .
  }
} LIMIT 100
"

# Must return empty result set for production deployment
```

### 4. Production Promotion

```bash
# Create production repository
curl -X POST "http://your-sparql-endpoint/repositories" \
  -H "Content-Type: application/json" \
  -d '{"id": "arden-prod", "type": "owlim:MonitorRepository"}'

# Copy validated data from stage to prod
curl -X POST "http://your-sparql-endpoint/arden-prod" \
  -H "Content-Type: application/sparql-update" \
  -d "
COPY <arden-stage:graph:ontology> TO <graph:ontology> ;
COPY <arden-stage:graph:mappings> TO <graph:mappings> ;
COPY <arden-stage:graph:shapes> TO <graph:shapes> ;
"

# Run final health check on production
curl -X POST "http://your-sparql-endpoint/arden-prod" \
  -H "Content-Type: application/sparql-query" \
  --data-binary @queries/probe-health-dashboard.rq
```

## Named Graphs Strategy

### Graph Organization
```
graph:ontology      → Core Arden ontology modules (READ-ONLY post-deploy)
graph:mappings      → Code schemes, units normalization (UPDATE quarterly)
graph:shapes        → SHACL validation rules (UPDATE with ontology)

graph:data:real:nass2024    → USDA NASS data by year
graph:data:real:rma2024     → RMA insurance data by year
graph:data:real:census2024  → Census/ACS socioeconomic data

graph:views         → Materialized county/year aggregates (REBUILD nightly)
graph:quarantine    → Invalid data for review (ARCHIVE monthly)
```

### Access Control Matrix
| Graph | Read | Write | Admin |
|-------|------|-------|--------|
| ontology | all | data-arch | data-arch |
| mappings | all | data-arch | data-arch |
| shapes | all | data-arch | data-arch |
| data:* | analysts | etl-service | data-arch |
| views | all | etl-service | ops |
| quarantine | analysts | etl-service | ops |

## Scale-Out ETL Pipeline

### Batch Processing Gates
```bash
# County-level batch validation (example: Iowa counties)
for county_fips in 19001 19003 19005; do
  echo "Processing county $county_fips..."

  # Extract county data
  python3 scripts/csv_to_rdf_template.py \
    data/raw/yield_${county_fips}.csv \
    temp/yield_${county_fips}.ttl

  # SHACL validation per batch
  pyshacl -s shapes/arden-shapes-l1.ttl \
    temp/yield_${county_fips}.ttl \
    --format turtle

  if [ $? -eq 0 ]; then
    # Load successful batch
    curl -X POST "http://sparql-endpoint/arden-prod/statements?context=graph:data:real:nass2024" \
      --data-binary @temp/yield_${county_fips}.ttl
  else
    # Quarantine failed batch
    curl -X POST "http://sparql-endpoint/arden-prod/statements?context=graph:quarantine" \
      --data-binary @temp/yield_${county_fips}.ttl
  fi
done
```

### Error Thresholds
- **FAIL pipeline**: >0.5% of rows fail SHACL L1 validation
- **WARN and continue**: 0.1-0.5% validation failures (log to quarantine)
- **PASS**: <0.1% validation failures

### Query Performance Optimization
```sparql
# Enable text indexing (GraphDB)
PREFIX luc: <http://www.ontotext.com/owlim/lucene#>
INSERT DATA {
  luc:myIndex luc:setParam "properties" .
  luc:myIndex luc:createConnector "rdfs:label" .
}

# Enable geospatial indexing
PREFIX geo: <http://www.ontotext.com/owlim/geo#>
INSERT DATA {
  geo:myGeoIndex geo:setParam "geosparql:asWKT" .
}
```

## Governance & Change Control

### Pull Request Requirements
1. **ROBOT Reasoning**: `robot reason --reasoner HermiT --input ontology/ --output temp/reasoned.ttl`
2. **SHACL Validation**: All L1, L2, L3 tiers must pass on sample data
3. **Health Checks**: 5 observability queries must return PASS status
4. **Competency Tests**: At least 1 query from `queries/competency/` must return plausible results

### Mapping Policy
- **Default**: `skos:closeMatch` for external mappings
- **Elevation to `skos:exactMatch`**: Requires short rationale in PR description
- **`owl:equivalentClass`**: Reserved for verified semantic equivalence

### Deprecation Process
1. Mark ontology terms: `owl:deprecated "true"^^xsd:boolean`
2. Add `rdfs:comment "Deprecated in v1.3.0. Use arden:NewTerm instead."`
3. Keep aliases active for one minor release
4. Remove in next major release

## Operational Monitoring

### Daily Health Checks (Automated)
```bash
# Cron job: 0 6 * * * /path/to/health-check.sh
#!/bin/bash
ENDPOINT="http://your-sparql-endpoint/arden-prod"
RESULTS=$(curl -s -X POST "$ENDPOINT" --data-binary @queries/probe-health-dashboard.rq)

if echo "$RESULTS" | grep -q "FAIL"; then
  echo "❌ HEALTH CHECK FAILED" | mail -s "Arden Ontology Alert" ops@your-org.com
  exit 1
elif echo "$RESULTS" | grep -q "WARN"; then
  echo "⚠️ HEALTH CHECK WARNINGS" | mail -s "Arden Ontology Warning" ops@your-org.com
fi

echo "✅ All systems healthy"
```

### Key Performance Indicators
- **Data Completeness**: >99% of FarmParcels have geometry
- **Validation Success**: >99.5% of daily ingest passes SHACL L1
- **Query Performance**: <500ms for standard analytical queries
- **Availability**: >99.9% SPARQL endpoint uptime

## Emergency Procedures

### Rollback Process
```bash
# 1. Preserve current data
curl -X POST "http://sparql-endpoint/arden-prod" \
  -H "Content-Type: application/sparql-update" \
  -d "COPY DEFAULT TO <graph:backup:$(date +%Y%m%d-%H%M%S)>"

# 2. Restore previous release (example v1.1.0)
git checkout v1.1.0
bash scripts/release-package.sh
# Follow deployment steps 2-4 above

# 3. Notification
echo "Arden Ontology rolled back to v1.1.0 due to: $REASON" \
  | mail -s "URGENT: Ontology Rollback" stakeholders@your-org.com
```

### On-Call Troubleshooting

#### SHACL Validation Failures in Production
1. **Identify failing shape**: Check SHACL violation report for `sh:sourceShape`
2. **Locate problematic data**: Query `?focusNode` from validation report
3. **Quick fixes**: Update `shapes/arden-shapes-l1.ttl` to adjust thresholds temporarily
4. **Long-term**: Fix data quality at ETL source or update ontology constraints

#### Query Performance Degradation
1. **Check indexes**: Ensure text and geospatial indexes are built
2. **Analyze slow queries**: Enable query logging in triple store
3. **Query rewriting**: Use bound variables, avoid Cartesian joins
4. **Graph partitioning**: Consider separating historical vs current data

#### External Dependency Failures
1. **Check lockfile**: Verify external ontologies match expected checksums
2. **Mirror failover**: Use backup mirrors from `externals/LOCKFILE.md`
3. **Version pinning**: Never auto-update external dependencies in production

## Support Contacts

- **Data Architecture**: data-arch@your-org.com
- **ETL Operations**: etl-ops@your-org.com
- **On-Call (24/7)**: +1-555-0199 or oncall@your-org.com
- **Change Approvals**: architecture-board@your-org.com

## Disaster Recovery

### Backup Strategy
- **Daily**: Full repository export to S3/blob storage
- **Weekly**: SPARQL dump of all named graphs
- **Monthly**: Offline backup with external ontology snapshots

### Recovery Procedures
1. **Triple store failure**: Restore from most recent daily backup
2. **Data corruption**: Rebuild from ETL source data + validated ontology
3. **Network partition**: Failover to backup SPARQL endpoint
4. **Complete disaster**: Deploy from release artifact + restore data backups

**Recovery Time Objective (RTO)**: 4 hours
**Recovery Point Objective (RPO)**: 24 hours