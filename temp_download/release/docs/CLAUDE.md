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

# Create release package
bash scripts/release-package.sh
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
2. **Extract**: Create MIREOT subsets from large ontologies
3. **Merge**: Combine all components into unified ontology
4. **Reason**: Apply ELK reasoner for inference
5. **Validate**: Multi-level SHACL validation against sample data
6. **Package**: Generate release artifacts with provenance

## Data Domains

The ontology models:
- **Agricultural**: Crops, livestock, practices, yields via AGRO and Crop Ontology integration
- **Financial**: Agricultural loans, contracts via FIBO and ACTUS integration
- **Environmental**: Soil classification (USDA NRCS), climate, geospatial data
- **Statistical**: Multi-dimensional data cubes via RDF Data Cube and SDMX
- **Taxonomic**: Species classification via NCBI Taxonomy integration

## Development Workflow

1. **Modify core ontology**: Edit files in `ontology/` directory
2. **Update mappings**: Adjust bridge files in `mappings/` for external alignment
3. **Test integration**: Run `bash scripts/test_new_externals.sh`
4. **Validate data**: Use `bash scripts/validate_samples.sh` against sample datasets
5. **Build release**: Execute `bash scripts/build.sh` to generate merged artifacts