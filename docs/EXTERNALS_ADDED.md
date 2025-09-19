# External Ontologies Added to Arden v1.2.0

This document summarizes the external ontologies added to Arden Ontology v1.2.0 for enhanced agricultural, financial, and socioeconomic data modeling.

## Overview

Arden v1.2.0 adds **9 new external ontologies** via a combination of direct inclusion and MIREOT (Minimum Information to Reference an External Ontology Terminology) subsets to keep the merged ontology lightweight and focused.

## External Ontologies Added

### 1. **AGRO (Agronomy Ontology)**
- **Source**: `http://purl.obolibrary.org/obo/agro.owl`
- **Integration**: MIREOT subset (≤500 terms)
- **Purpose**: Agricultural practices, crop traits, agronomic variables
- **Bridge**: `mappings/arden-bridges-agro.ttl`
- **Key Classes**: Crop, AgriculturalPractice, Yield, GrowthStage

### 2. **Crop Ontology (Maize & Soybean)**
- **Sources**:
  - Maize: `https://cropontology.org/ontology/CO_322/rdf`
  - Soybean: `https://cropontology.org/ontology/CO_336/rdf`
- **Integration**: MIREOT subsets (≤100 terms each)
- **Purpose**: Crop-specific traits and phenotypic variables
- **Bridge**: Included in `mappings/arden-bridges-agro.ttl`

### 3. **FIBO (Financial Industry Business Ontology)**
- **Source**: `https://spec.edmcouncil.org/fibo/ontology/master/latest/`
- **Integration**: MIREOT subset (≤300 terms) - FND/BE/FBC-Debt modules only
- **Purpose**: Financial entities, loans, interest rates, payments
- **Bridge**: `mappings/arden-bridges-fibo.ttl`
- **Scope**: Foundations, Business Entities, Debt/Loans (no securities/derivatives)

### 4. **ACTUS (Algorithmic Contract Types)**
- **Source**: `https://spec.edmcouncil.org/fibo/ontology/master/latest/ACTUS/`
- **Integration**: Direct inclusion (core contract types only)
- **Purpose**: Standardized loan contract modeling (ANN, LAM, PAM)
- **Bridge**: `mappings/arden-bridges-actus.ttl`
- **Key Parameters**: Notional, interest rate, day count convention, payment frequency

### 5. **RDF Data Cube (QB)**
- **Source**: `http://purl.org/linked-data/cube#`
- **Integration**: Direct inclusion
- **Purpose**: Statistical data structure definitions and observations
- **Bridge**: `mappings/arden-bridges-sdmx.ttl`

### 6. **SDMX (Statistical Data and Metadata Exchange)**
- **Sources**:
  - `http://purl.org/linked-data/sdmx/2009/dimension#`
  - `http://purl.org/linked-data/sdmx/2009/measure#`
  - `http://purl.org/linked-data/sdmx/2009/attribute#`
- **Integration**: Direct inclusion
- **Purpose**: Standard dimensions (refArea, timePeriod), measures (obsValue), attributes (unitMeasure)
- **Bridge**: `mappings/arden-bridges-sdmx.ttl`

### 7. **W3C Time Ontology**
- **Source**: `http://www.w3.org/2006/time#`
- **Integration**: Direct inclusion
- **Purpose**: Temporal concepts for agricultural seasons and financial periods
- **Status**: Already partially present, now complete

### 8. **USDA Soil Taxonomy (Derived)**
- **Source**: **CUSTOM SKOS SCHEME** (no official RDF available)
- **Integration**: `externals/derived/usda-soil.skos.ttl`
- **Purpose**: Soil classification for farm parcels (12 soil orders)
- **Bridge**: `mappings/arden-bridges-soil.ttl`
- **Content**: Alfisols, Mollisols, Vertisols, etc. with SKOS broader/narrower relationships

### 9. **NCBITaxon (NCBI Taxonomy)**
- **Source**: `http://purl.obolibrary.org/obo/ncbitaxon.owl`
- **Integration**: MIREOT subset (≤50 terms)
- **Purpose**: Species identification for crops and livestock
- **Key Species**: Zea mays (corn), Glycine max (soybean), Bos taurus (cattle)

## Integration Strategy

### MIREOT Approach
- **Large ontologies** (AGRO, FIBO, NCBITaxon, Crop Ontology) use MIREOT extraction
- **Small vocabularies** (QB, SDMX, Time) included directly
- **Derived ontologies** created for missing standards (USDA Soil)

### Bridge Mappings
- **5 new bridge files** created in `mappings/arden-bridges-*.ttl`
- Use `rdfs:subClassOf` and `skos:exactMatch` for alignment
- Avoid `owl:equivalentClass` to maintain modularity
- Include restrictions and constraints for data validation

### SHACL Validation
- **5 new SHACL shape files** created for domain validation:
  - `shapes/arden-shapes-crops.ttl` - Crop/variety labeling, yield units, BBCH growth stages
  - `shapes/arden-shapes-finance.ttl` - Loan validation, ACTUS parameters, payment schedules
  - `shapes/arden-shapes-socio.ttl` - QB/SDMX compliance, county FIPS codes, time periods
  - `shapes/arden-shapes-soil.ttl` - USDA taxonomy compliance, pH/organic matter ranges
  - `shapes/arden-shapes-taxonomy.ttl` - Species validation, NCBITaxon alignment

## Build Process Updates

### Scripts Modified
- **`scripts/fetch_ontologies.sh`**: Added downloads for all new externals
- **`scripts/extract_mireot_subsets.sh`**: New ROBOT MIREOT extraction pipeline
- **`scripts/build.sh`**: Updated merge process, SHACL validation, versioning
- **`scripts/test_new_externals.sh`**: Drop-in test script for CI/CD

### File Structure
```
externals/
├── subsets/           # MIREOT extractions (agro_subset.owl, fibo_subset.owl, etc.)
├── derived/           # Custom ontologies (usda-soil.skos.ttl)
├── fibo-modules/      # FIBO module downloads
└── [direct files]     # QB, SDMX, Time, etc.

mireot/
├── agro_terms.txt     # Term lists for MIREOT extraction
├── fibo_terms.txt
└── [other term lists]

mappings/
├── arden-bridges-agro.ttl    # New bridge mappings
├── arden-bridges-fibo.ttl
├── arden-bridges-actus.ttl
├── arden-bridges-sdmx.ttl
└── arden-bridges-soil.ttl

shapes/
├── arden-shapes-crops.ttl     # New domain validation
├── arden-shapes-finance.ttl
├── arden-shapes-socio.ttl
├── arden-shapes-soil.ttl
└── arden-shapes-taxonomy.ttl
```

## Impact and Benefits

### Agricultural Modeling
- **Standardized crop traits** via AGRO and Crop Ontology alignment
- **Growth stage tracking** with BBCH code validation
- **Yield measurement** with unit standardization and range validation

### Financial Modeling
- **Loan structuring** with FIBO business entity and contract modeling
- **Cash flow generation** via ACTUS contract type parameterization
- **Interest rate** and payment schedule validation

### Statistical Data
- **QB/SDMX compliance** for NASS, Census, RMA dataset integration
- **County-level aggregation** with FIPS code validation
- **Time series** modeling with proper temporal dimensions

### Data Quality
- **Multi-tier SHACL validation** (L1 permissive → L3 enterprise-strict)
- **Cross-domain consistency** checking (no mixing crop/livestock species)
- **Unit standardization** and range validation for measurements

## Compatibility

- **Backward compatible** with existing Arden v1.1.x data
- **Graceful degradation** - external validation warnings don't block processing
- **Modular imports** - can selectively exclude external domains if needed
- **Version pinning** with SHA256 integrity checking in `externals/LOCKFILE.md`

## Testing

Run the complete external ontology test suite:
```bash
chmod +x scripts/test_new_externals.sh
./scripts/test_new_externals.sh
```

This validates:
1. External ontology fetching
2. MIREOT subset extraction
3. Merged ontology building
4. SHACL validation with sample data
5. Health monitoring queries

---
*Generated for Arden Ontology v1.2.0 - 2024-09-19*