# Arden Ontology v1.2.0

A comprehensive, multi-domain ontology for agricultural, environmental, financial, and socioeconomic data modeling.

## Overview

Arden Ontology provides a unified semantic framework integrating:

- **Agricultural Domain**: Crops, livestock, practices, yields, and agronomy
- **Financial Domain**: Agricultural loans, contracts, and financial instruments
- **Environmental Domain**: Soil classification, geospatial data, and climate
- **Statistical Domain**: Multi-dimensional data cubes and statistical indicators
- **Taxonomic Domain**: Species classification and biological taxonomy

## New in v1.2.0: External Ontology Integration

This version adds comprehensive integration with 9 major external ontologies:

### Core Agricultural & Environmental
- **AGRO** (Agronomy Ontology) - Crop science and agricultural practices
- **Crop Ontology** - Standardized crop trait and measurement vocabularies
- **USDA NRCS Soil Taxonomy** - US soil classification system (12 orders)
- **NCBI Taxonomy** - Species and organism classification

### Financial & Statistical
- **FIBO Core** - Financial Industry Business Ontology (minimal subset)
- **ACTUS** - Algorithmic Contract Types for loan modeling
- **RDF Data Cube** - Multi-dimensional statistical data representation
- **SDMX** - Statistical Data and Metadata eXchange vocabularies

### Foundational
- **W3C Time** - Temporal concepts and time-based reasoning

## Architecture

```
arden-ontology/
├── ontology/           # Core Arden modules
│   ├── arden-core.ttl  # Foundational concepts
│   ├── arden-ag.ttl    # Agricultural domain
│   ├── arden-fin.ttl   # Financial domain
│   └── arden-geo.ttl   # Geospatial concepts
├── externals/          # External ontologies
│   ├── agro-full.owl   # AGRO (downloaded)
│   ├── qb.ttl          # RDF Data Cube
│   ├── sdmx-*.ttl      # SDMX vocabularies
│   └── derived/        # Custom SKOS schemes
├── mappings/           # Bridge mappings
│   ├── arden-bridges-agro.ttl
│   ├── arden-bridges-fibo.ttl
│   └── ...
├── shapes/             # SHACL validation
│   ├── arden-shapes-crops.ttl
│   ├── arden-shapes-finance.ttl
│   └── ...
└── scripts/            # Build & test tools
    ├── fetch_ontologies.sh
    ├── test_new_externals.sh
    └── release-package.sh
```

## Getting Started

### Prerequisites
- Python 3.8+ with rdflib
- Bash shell environment
- Internet connection for downloading externals

### Quick Start

1. **Fetch external ontologies**:
   ```bash
   bash scripts/fetch_ontologies.sh
   ```

2. **Test the integration**:
   ```bash
   bash scripts/test_new_externals.sh
   ```

3. **Build merged release**:
   ```bash
   export ARDEN_ONTOLOGY_VERSION=v1.2.0
   python -c "exec(open('scripts/create_merged_ontology.py').read())"
   ```

### MIREOT Subsets

Large external ontologies use MIREOT (Minimum Information to Reference External Ontology Terminology) for lightweight integration:

- **AGRO**: ≤500 key agricultural terms
- **Crop Ontology**: ≤100 terms per crop species
- **FIBO**: ≤300 core financial concepts
- **NCBITaxon**: ≤50 agricultural species

## Integration Strategy

### Bridge Mappings
- Use `rdfs:subClassOf` and `skos:exactMatch` for semantic alignment
- Avoid `owl:equivalentClass` to prevent reasoning conflicts
- Maintain clear provenance and source attribution

### SHACL Validation
Multi-tier validation levels:
- **L1 (Permissive)**: Basic structure validation
- **L2 (Standard)**: Business rule enforcement
- **L3 (Enterprise)**: Strict compliance checking

### Modular Design
- Core Arden concepts remain independent
- External mappings are optional and non-breaking
- Support for incremental adoption

## Usage Examples

### Agricultural Data Modeling
```turtle
@prefix arden-ag: <https://arden.ag/ont/ag#> .
@prefix agro: <http://purl.obolibrary.org/obo/> .

:my-corn-field a arden-ag:Field ;
    arden-ag:growsCrop :corn-crop .

:corn-crop a arden-ag:Crop ;
    rdfs:subClassOf agro:AGRO_00000003 ;  # agro:crop
    arden-ag:hasYield :yield-2024 .
```

### Financial Loan Modeling
```turtle
@prefix arden-fin: <https://arden.ag/ont/fin#> .
@prefix fibo-dbt: <https://spec.edmcouncil.org/fibo/ontology/FBC/DebtAndEquities/Debt/> .

:farm-loan a arden-fin:AgriculturalLoan ;
    rdfs:subClassOf fibo-dbt:Loan ;
    arden-fin:hasPrincipalAmount 500000.00 ;
    arden-fin:financesAsset :my-corn-field .
```

### Statistical Data Cubes
```turtle
@prefix qb: <http://purl.org/linked-data/cube#> .
@prefix sdmx-measure: <http://purl.org/linked-data/sdmx/2009/measure#> .

:crop-yield-data a qb:DataSet ;
    qb:structure :yield-dsd .

:obs-1 a qb:Observation ;
    qb:dataSet :crop-yield-data ;
    sdmx-measure:obsValue 8.5 ;
    arden-ag:refCrop :corn-crop .
```

## Version Information

- **Version**: 1.2.0
- **Release Date**: 2024
- **License**: [Specify license]
- **Namespace**: https://arden.ag/ont/

## Contributing

External ontology integration follows these principles:
1. Use authoritative sources with stable PURLs
2. Implement MIREOT for large ontologies (>1000 terms)
3. Create bridge mappings, not direct imports
4. Provide SHACL shapes for validation
5. Include comprehensive test coverage

## Support

For questions about Arden Ontology integration:
- Review the `/docs` directory for detailed specifications
- Check `/shapes` for validation requirements
- See `/mappings` for semantic alignments
- Run `/scripts/test_new_externals.sh` for troubleshooting