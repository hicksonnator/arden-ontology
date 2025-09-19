# Arden Ontology Governance & Change Control

**Version**: 1.2.0
**Effective Date**: 2024-12-19
**Next Review**: 2025-06-19

## Governance Structure

### Decision-Making Authority

**Data Architecture Board**
- **Chair**: Chief Data Officer
- **Members**: Senior Data Architect, Domain SMEs, Engineering Lead
- **Responsibilities**: Ontology strategy, major version approvals, external mappings policy
- **Meeting Cadence**: Monthly, with ad-hoc reviews for urgent changes

**Ontology Stewards (Day-to-Day)**
- **Lead**: Senior Data Architect
- **Members**: Data Engineers (2), Domain Experts (2)
- **Responsibilities**: PR reviews, minor releases, mapping updates, SHACL tuning
- **Meeting Cadence**: Weekly standup, daily Slack monitoring

**Agricultural Domain Council**
- **Members**: Agronomists, Farm Operations, Commodity Trading, Risk Management
- **Responsibilities**: Domain expertise validation, use case priorities, competency queries
- **Meeting Cadence**: Quarterly alignment, on-demand consultation

## Change Classification

### Major Changes (Architecture Board Approval Required)
- **New domain modules** (e.g., arden-weather.ttl, arden-livestock.ttl)
- **Breaking changes** to core classes or properties
- **External ontology upgrades** (SOSA, QUDT version changes)
- **New data sources** requiring schema extensions
- **Security model changes** (access control, PII handling)

**Process**: RFC document → Board review → 2-week comment period → Decision

### Minor Changes (Steward Team Approval)
- **Property additions** to existing classes
- **SHACL constraint adjustments** (threshold tuning)
- **Mapping updates** for code schemes (FIPS, NASS updates)
- **Documentation improvements**
- **Bug fixes** that don't affect semantics

**Process**: PR → 2-steward approval → Merge → Deploy

### Patch Changes (Single Steward Approval)
- **Typo fixes** in labels or comments
- **Example data updates**
- **Build script improvements**
- **Non-breaking formatting changes**

**Process**: PR → 1-steward approval → Merge

## Pull Request Requirements

### Automated Checks (All PRs)
```bash
# 1. Syntax validation
robot validate --input ontology/*.ttl

# 2. Reasoning consistency check
robot reason --reasoner HermiT --input ontology/ --output temp/reasoned.ttl

# 3. SHACL validation on sample data
pyshacl -s shapes/arden-shapes-l1.ttl data/samples.ttl
pyshacl -s shapes/arden-shapes-l2.ttl data/samples.ttl
pyshacl -s shapes/arden-shapes-l3.ttl data/samples.ttl

# 4. Health dashboard query
sparql --query queries/probe-health-dashboard.rq --data temp/reasoned.ttl

# 5. Competency query regression test
for query in queries/competency/*.rq; do
  result=$(sparql --query "$query" --data temp/reasoned.ttl)
  if [ -z "$result" ]; then
    echo "FAIL: $query returned no results"
    exit 1
  fi
done
```

### Manual Review Checklist

**For All Changes**:
- [ ] Clear PR title and description
- [ ] Links to relevant issues or RFCs
- [ ] Backward compatibility assessment
- [ ] Impact on existing queries documented
- [ ] Example usage provided

**For Ontology Changes**:
- [ ] New terms have clear definitions (`rdfs:comment`)
- [ ] Domain and range specified for all properties
- [ ] Follows existing naming conventions
- [ ] Adequate examples in documenation

**For Mapping Changes**:
- [ ] Source documentation referenced
- [ ] Mapping rationale explained (`skos:closeMatch` vs `skos:exactMatch`)
- [ ] External URI stability verified
- [ ] Update frequency documented

**For SHACL Changes**:
- [ ] Constraint thresholds justified with data analysis
- [ ] Error messages are actionable for data producers
- [ ] Performance impact on validation assessed
- [ ] Gradual rollout plan for stricter constraints

## External Mapping Policy

### Mapping Confidence Levels

**`skos:exactMatch`** (Reserved for verified equivalence)
- Same semantic definition
- Same usage context
- Verified by domain experts
- **Requires**: Brief rationale in PR + domain SME sign-off

**`skos:closeMatch`** (Default for most external mappings)
- Similar concepts, minor differences
- Different granularity or scope
- Useful for discovery and enrichment
- **Requires**: Source documentation link

**`skos:relatedMatch`** (Broad conceptual relationships)
- Related but distinct concepts
- Cross-domain connections
- Research and exploration use cases

### Approved External Vocabularies

**Tier 1: Stable, Well-Governed**
- AGROVOC (FAO agricultural thesaurus)
- DBpedia (Wikipedia-derived)
- Wikidata (community-curated)
- USDA controlled vocabularies

**Tier 2: Domain-Specific, Reliable**
- BBCH growth stages
- Soil taxonomy (USDA-NRCS)
- Plant trait ontology (TO)
- Environment ontology (ENVO)

**Tier 3: Emerging, Experimental**
- Research ontologies (OBO Foundry)
- Industry-specific vocabularies
- Regional/national schemes

**Policy**: Tier 1 mappings allowed with steward approval. Tier 2 requires domain SME review. Tier 3 requires Architecture Board approval.

## Deprecation & Versioning Strategy

### Term Lifecycle

**Active** → **Deprecated** → **Obsolete** → **Removed**

```turtle
# Example deprecation annotation
arden:OldTermName a owl:Class ;
  owl:deprecated "true"^^xsd:boolean ;
  rdfs:comment "Deprecated in v1.4.0. Use arden:NewTermName instead." ;
  owl:equivalentClass arden:NewTermName ;  # Temporary bridge
  dct:isReplacedBy arden:NewTermName .
```

### Deprecation Timeline
- **v1.4.0**: Mark as deprecated, add replacement mapping
- **v1.5.0**: Issue warnings for deprecated term usage
- **v2.0.0**: Remove deprecated terms (major version bump)

### Version Compatibility Matrix

| Change Type | Version Impact | Compatibility |
|-------------|----------------|---------------|
| New classes/properties | Minor (1.3.0) | Backward compatible |
| New constraints | Minor (1.3.0) | May break invalid data |
| Deprecated terms | Minor (1.3.0) | Backward compatible |
| Removed terms | Major (2.0.0) | Breaking change |
| Changed semantics | Major (2.0.0) | Breaking change |

## Quality Assurance Process

### Continuous Integration Pipeline
```yaml
name: Ontology CI/CD
on: [push, pull_request]

jobs:
  validate:
    steps:
      - name: Syntax Check
        run: robot validate ontology/*.ttl

      - name: Reasoning Test
        run: robot reason --reasoner elk ontology/*.ttl

      - name: SHACL Validation
        run: |
          pyshacl -s shapes/arden-shapes-l1.ttl data/samples.ttl
          pyshacl -s shapes/arden-shapes-l2.ttl data/samples.ttl

      - name: Health Dashboard
        run: sparql --query queries/probe-health-dashboard.rq --data ontology/

      - name: Performance Test
        run: |
          # Test query performance on sample data
          timeout 30s sparql --query queries/competency/yield-by-county.rq

  security:
    steps:
      - name: PII Scan
        run: |
          # Check for accidental PII in example data
          grep -r "ssn\|tax_id\|social_security" data/ && exit 1 || true

      - name: External URL Check
        run: |
          # Verify external mappings are still reachable
          ./scripts/check-external-mappings.sh
```

### Quarterly Reviews

**Data Quality Assessment**
- Analyze SHACL violation reports from production
- Review quarantined data patterns
- Adjust validation thresholds based on real-world data

**Mapping Accuracy Audit**
- Spot-check external mappings for link rot
- Validate mapping accuracy with domain experts
- Update deprecated external vocabularies

**Performance Optimization**
- Query performance analysis on production workload
- Index optimization recommendations
- Graph partitioning effectiveness review

### Annual Governance Review

**Policy Effectiveness**
- Change process efficiency metrics
- Stakeholder satisfaction survey
- Decision-making speed vs quality tradeoffs

**Technological Currency**
- External ontology version updates
- New W3C standards adoption
- Tool chain and pipeline improvements

**Strategic Alignment**
- Business priorities alignment
- New use case requirements
- Competitive landscape analysis

## Incident Response

### Severity Classification

**Severity 1: Production Outage**
- SPARQL endpoint unavailable
- Corrupt ontology preventing queries
- Security breach or data exposure

**Severity 2: Data Quality Issues**
- Widespread SHACL validation failures
- Incorrect mappings affecting analytics
- Performance degradation >2x normal

**Severity 3: Minor Issues**
- Documentation errors
- Non-critical constraint failures
- Cosmetic problems

### Response Procedures

**Sev 1 (Immediate Response)**
1. **Emergency contacts**: Page on-call architect + ops team
2. **Communications**: Notify stakeholders within 30 minutes
3. **Rollback authority**: On-call can rollback without approval
4. **Post-incident**: Full RCA required within 5 business days

**Sev 2 (Same Day Response)**
1. **Assessment**: Steward team evaluates impact within 4 hours
2. **Fix timeline**: Resolution plan within 1 business day
3. **Communication**: Status updates every 8 hours until resolved
4. **Review**: Lessons learned discussion in next weekly meeting

**Sev 3 (Planned Response)**
1. **Triage**: Next business day evaluation
2. **Scheduling**: Fix in next planned release or maintenance window
3. **Documentation**: Issue tracked in project management system

## Training & Onboarding

### New Team Member Onboarding

**Week 1: Ontology Fundamentals**
- RDF/OWL concepts
- Arden domain model walkthrough
- Tool setup (Protégé, SPARQL, validation)

**Week 2: Development Process**
- Git workflow and PR templates
- Build system and validation pipeline
- SHACL constraint development

**Week 3: Domain Knowledge**
- Agricultural domain deep dive with SMEs
- Use case workshops
- Query development practice

**Week 4: Production Systems**
- Deployment process
- Monitoring and alerting
- Incident response procedures

### Ongoing Education

**Monthly**: Technical deep-dive sessions
**Quarterly**: External ontology updates and trends
**Annually**: Conference attendance or industry training
**Ad-hoc**: Guest expert sessions on specific domains

## Compliance & Audit Trail

### Change Documentation Requirements

**All Changes Must Include**:
- Rationale and business justification
- Impact assessment (systems, users, performance)
- Testing results and validation evidence
- Rollback procedures

**Audit Trail Retention**:
- Git history preserved permanently
- Decision rationales in PR descriptions
- Meeting minutes for Architecture Board decisions
- External communication logs

### Regulatory Considerations

**Data Governance Compliance**:
- PII handling documentation
- Data lineage traceability
- Access control audit logs
- International data transfer compliance

**Industry Standards**:
- ISO 25964 (Thesauri and interoperability)
- FAIR data principles compliance
- Agricultural data standards alignment

This governance framework ensures the Arden Ontology remains stable, accurate, and aligned with business needs while enabling innovation and evolution.