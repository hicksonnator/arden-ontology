# Arden Ontology Production Rollout Guide

## Pre-Deployment Checklist

### Infrastructure Requirements
- [ ] RDF triple store (Blazegraph, Stardog, or GraphDB)
- [ ] SPARQL endpoint configuration
- [ ] Geospatial extensions enabled (GeoSPARQL)
- [ ] Backup and recovery procedures
- [ ] Monitoring and alerting setup

### Validation Pipeline
- [ ] SHACL validation enabled (use shapes/ directory)
- [ ] ETL guardrails configured (scripts/csv_to_rdf_template.py)
- [ ] Data quality thresholds defined
- [ ] Error notification system active

### Security Checklist
- [ ] External ontology checksums verified (externals/LOCKFILE.md)
- [ ] Access controls configured
- [ ] Audit logging enabled
- [ ] Sensitive data anonymization confirmed

## Deployment Steps

### 1. Infrastructure Setup
```bash
# Load core ontology
curl -X POST -H "Content-Type: text/turtle" \
  --data-binary @ontology/arden-core.ttl \
  http://your-sparql-endpoint/data

# Load all modules
for f in ontology/*.ttl; do
  curl -X POST -H "Content-Type: text/turtle" \
    --data-binary @$f \
    http://your-sparql-endpoint/data
done
```

### 2. Validation Setup
```bash
# Configure SHACL validation
for f in shapes/*.ttl; do
  # Load into shapes graph
  curl -X POST -H "Content-Type: text/turtle" \
    --data-binary @$f \
    http://your-sparql-endpoint/shapes
done
```

### 3. Code Schemes and Mappings
```bash
# Load controlled vocabularies
for f in mappings/*.ttl; do
  curl -X POST -H "Content-Type: text/turtle" \
    --data-binary @$f \
    http://your-sparql-endpoint/codes
done
```

### 4. Sample Data (Optional)
```bash
# Load sample data for testing
for f in data/*.ttl; do
  curl -X POST -H "Content-Type: text/turtle" \
    --data-binary @$f \
    http://your-sparql-endpoint/test-data
done
```

## Data Ingest Pipeline

### ETL Configuration
1. Use `scripts/csv_to_rdf_template.py` as template
2. Configure validation thresholds per data source
3. Set up duplicate detection and unit normalization
4. Enable error reporting and notifications

### Monitoring Queries
```sparql
# Data quality dashboard queries
PREFIX arden: <https://arden.ag/ont/core#>
PREFIX sosa: <http://www.w3.org/ns/sosa/>

# Count observations by type
SELECT ?type (COUNT(*) as ?count) WHERE {
  ?obs a ?type .
  FILTER(STRSTARTS(STR(?type), "https://arden.ag/ont/"))
} GROUP BY ?type

# Recent ingest activity
SELECT ?dataset ?timestamp WHERE {
  ?dataset dct:modified ?timestamp .
  FILTER(?timestamp > NOW() - "P1D"^^xsd:duration)
} ORDER BY DESC(?timestamp)
```

## Rollback Procedures

### Emergency Rollback
1. Preserve current data in backup graph
2. Restore previous validated snapshot
3. Notify stakeholders of rollback
4. Investigate and document issues

### Validation Failures
1. Halt automated ingest
2. Review SHACL violation reports
3. Fix data quality issues at source
4. Re-validate before resuming

## Support Contacts

- **Data Architecture**: [team@your-org.com]
- **Operations**: [ops@your-org.com]
- **Emergency**: [emergency@your-org.com]

## Success Metrics

- [ ] Zero SHACL validation errors in production
- [ ] <1% data quality warnings
- [ ] ETL processing < 2 hours for daily batch
- [ ] Query response times < 500ms for standard reports

