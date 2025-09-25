# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Arden Ontology v1.2.0 is a comprehensive, multi-domain ontology for agricultural, environmental, financial, and socioeconomic data modeling. It integrates 9 major external ontologies including AGRO, Crop Ontology, FIBO, NCBI Taxonomy, and others through MIREOT (Minimum Information to Reference External Ontology Terminology) subsets.

## Key Commands

### Build and Development
```bash
# Fetch external ontologies
make fetch
# OR
bash scripts/fetch_ontologies.sh

# Build the complete merged ontology
make build
# OR
bash scripts/build.sh

# Test external ontology integration
bash scripts/test_new_externals.sh

# Validate sample data with SHACL
bash scripts/validate_samples.sh

# Create release package with validation
ARDEN_VERSION=v1.2.2 bash scripts/release-package.sh
```

### Environment Setup
The project uses a Python virtual environment (`.venv/`) with semantic web libraries. Key tools required:
- `robot` - Ontology toolkit for merging and reasoning
- `pyshacl` - SHACL validation (install with `pip install pyshacl`)
- `rdflib` - Python RDF processing library

## Architecture

The ontology follows a modular design with clear separation between:

### Core Components
- **Core Arden modules** (`ontology/arden-*.ttl`): Foundational concepts for agricultural, financial, and geospatial domains
- **Bridge mappings** (`mappings/arden-bridges-*.ttl`): Semantic alignments between Arden and external ontologies using `rdfs:subClassOf` and `skos:exactMatch` (avoiding `owl:equivalentClass`)
- **SHACL validation** (`shapes/`): Multi-tier validation (L1=ingest-safe, L2=production, L3=analytics)

### External Integration
- **MIREOT subsets** (`externals/subsets/`): Lightweight extracts from large ontologies (≤500 terms from AGRO, ≤300 from FIBO)
- **Full external ontologies** (`externals/`): Complete vocabularies for RDF Data Cube, SDMX, W3C Time, etc.
- **Derived ontologies** (`externals/derived/`): Custom SKOS schemes like USDA Soil Taxonomy

### Build Process
1. **Fetch**: Download external ontologies from authoritative sources
2. **Preprocess**: Sanitize external ontologies to remove unparseable OWL constructs
3. **Extract**: Create MIREOT subsets from large ontologies
4. **Merge**: Combine all components into unified ontology
5. **Reason**: Apply ELK reasoner for inference
6. **Validate**: Multi-level SHACL validation against sample data
7. **Package**: Generate release artifacts with provenance

## Data Domains

The ontology models:
- **Agricultural**: Crops, livestock, practices, yields via AGRO and Crop Ontology integration
- **Financial**: Agricultural loans, contracts via FIBO and ACTUS integration
- **Environmental**: Soil classification (USDA NRCS), climate, geospatial data
- **Statistical**: Multi-dimensional data cubes via RDF Data Cube and SDMX
- **Taxonomic**: Species classification via NCBI Taxonomy integration

## External Ontology Preprocessing

**Problem**: External ontologies often contain complex OWL constructs that ROBOT cannot parse, causing build failures.

**Solution**: Automated preprocessing pipeline that sanitizes external ontologies while preserving functionality.

### Preprocessing Script
```bash
# Run preprocessing manually (automatic in build scripts)
bash scripts/preprocess-externals-simple.sh
```

### What Gets Preprocessed
- **Complex OWL Constructs**: `owl:equivalentProperty`, `owl:withRestrictions`, blank node expressions
- **Problematic Files**: `externals/qb.ttl` (RDF Data Cube), `externals/time.rdf` (W3C Time)
- **Output Location**: `externals/cleaned/` directory with sanitized versions

### Preprocessing Strategy
1. **Try ROBOT merge first**: Attempt to parse with ROBOT, which skips unparseable triples
2. **Create minimal fallbacks**: If parsing fails completely, generate minimal working versions with just namespace declarations
3. **Validate cleaned versions**: Ensure all cleaned files can be successfully parsed by ROBOT
4. **Copy working files**: Files that parse correctly are copied as-is to `externals/cleaned/`

### Build Integration
All enhanced build scripts automatically detect missing cleaned files and run preprocessing:
```bash
# Auto-preprocessing in build scripts
if [ ! -d "externals/cleaned" ] || [ $(find externals/cleaned -name "*.ttl" | wc -l) -eq 0 ]; then
    echo "Running external preprocessing..."
    bash scripts/preprocess-externals-simple.sh
fi
```

### Minimal vs Full Enhanced Builds
- **Minimal Enhanced** (`build-enhanced-v1.2.2-minimal.sh`): Uses only core working components (911 terms)
- **Full Enhanced** (`build-enhanced-v1.2.2.sh`): Includes all domain integrations and complex reasoning

## Development Workflow

1. **Modify core ontology**: Edit files in `ontology/` directory
2. **Update mappings**: Adjust bridge files in `mappings/` for external alignment
3. **Test integration**: Run `bash scripts/test_new_externals.sh`
4. **Validate data**: Use `bash scripts/validate_samples.sh` against sample datasets
5. **Build release**: Execute `bash scripts/build.sh` to generate merged artifacts

## 🚨 CRITICAL: Release Validation Process

**NEVER ship an incomplete ontology!** The release process includes multiple validation gates:

### Validation Thresholds (Update as ontology grows)
- **Individual modules**: ≥320 terms (current baseline: 332)
- **Enhanced complete**: ≥1,250 terms (current baseline: 1,268 terms)
- **Markets module**: ≥50 terms (Yahoo Finance integration)
- **Core module**: ≥5 terms (basic ontology structure)
- **Integration module**: ≥60 terms (external integrations)

### Validation Gates
1. **Build Staleness Check**: Detects if source files are newer than cached builds
2. **Term Count Validation**: Ensures all modules meet minimum thresholds
3. **Market Data Integration**: Verifies Yahoo Finance terms (CornFuture, SoybeanFuture, etc.)
4. **Final Archive Validation**: Re-validates archive contents before deployment

### Release Process Commands
```bash
# Run with comprehensive validation (recommended)
ARDEN_VERSION=v1.2.2 bash scripts/release-package.sh

# The script will:
# 1. Detect stale builds and rebuild automatically
# 2. Validate all module term counts
# 3. Check for critical market data integration
# 4. Create validated archive
# 5. Provide exact GitHub release command

# ONLY use the exact archive and command provided by the script!
```

### If Validation Fails
- **DO NOT** bypass validation or manually create releases
- **DO NOT** push incomplete ontologies to GitHub
- **CHECK** build logs for syntax errors in ontology files
- **VERIFY** all ontology modules have expected content
- **REBUILD** from clean state if necessary

### Validation Failure Troubleshooting
```bash
# Check individual module term counts
find ontology -name "*.ttl" -exec bash -c 'echo "$1: $(grep -c "a owl:Class\|a owl:ObjectProperty\|a owl:DatatypeProperty" "$1")"' _ {} \;

# Verify enhanced build exists and is recent
ls -la build/arden-enhanced-v1.2.1.ttl

# Force rebuild if stale
rm -f build/arden-enhanced-v1.2.1.ttl
bash scripts/build-enhanced-v1.2.1.sh

# Check for Yahoo Finance market data
grep -c "CornFuture\|SoybeanFuture\|WheatFuture\|OHLCVObservation" ontology/arden-markets.ttl
```

### GitHub Release Command
**ALWAYS use the exact command provided by the validated release script:**
```bash
gh release create v1.2.2 --title "Arden Ontology v1.2.2" --notes "Enhanced ontology with 911 terms" "arden-ontology-production-v1.2.2-TIMESTAMP.tar.gz"
```