# Arden Ontology Scoping Table v1.2.0

## Module Architecture (ChatGPT-Aligned)

| Module | Size Target | Content Focus | Competency Questions Supported |
|--------|-------------|---------------|-------------------------------|
| **arden-core.ttl** | <50K | Basic agricultural & financial concepts | All (foundation) |
| **arden-ag.ttl** | <300K | AGRO micro-extract: ag-finance relevant terms | Crop qualification, yield conversion, collateral valuation |
| **arden-fin.ttl** | <300K | FIBO micro-extract: ag-relevant financial terms | Loan structuring, amortization, compliance |
| **arden-bridge.ttl** | <100K | Agriculture-finance semantic mappings | All bridge questions |

## FIBO Micro-Extract Scope (arden-fin.ttl)

### ✅ INCLUDE (Ag-Finance Essential)
| FIBO Term | Rationale | Competency Question |
|-----------|-----------|-------------------|
| `fibo-fbc-dae-dbt:Loan` | Core agricultural lending | "5-year corn loan structure" |
| `fibo-fbc-dae-dbt:Mortgage` | Farmland financing | "Farmland mortgage tied to yield" |
| `fibo-fnd-agr-ctr:Contract` | Loan agreements | "Farm Credit eligibility" |
| `fibo-fbc-dae-dbt:Collateral` | Asset-backed lending | "Collateral valuation" |
| `fibo-fbc-pas-caa:RepaymentSchedule` | Loan structuring | "Repayment schedules" |
| `fibo-fbc-pas-caa:AmortizationSchedule` | Mortgage payments | "Amortization structure" |
| `fibo-der-drc-comm:CommodityDerivative` | Futures pricing | "Wheat futures affect loan pricing" |
| `fibo-sec-dbt-mbs:MortgageBackedSecurity` | Securitization | "Insurance securitization" |

### ❌ EXCLUDE (Not Ag-Relevant)
- Equity markets (beyond ag commodities)
- Derivatives (except commodity futures)
- Investment banking products
- Insurance (except crop/collateral)

## AGRO Micro-Extract Scope (arden-ag.ttl)

### ✅ INCLUDE (Finance-Relevant Agriculture)
| AGRO Term | Rationale | Competency Question |
|-----------|-----------|-------------------|
| `agro:Crop` (corn, soybeans, wheat) | Core commodities | "Corn loan", "wheat futures" |
| `agro:CropYield` | Loan collateral basis | "Yield-tied mortgage", "150 bushels/acre" |
| `agro:FarmingSystem` | Risk assessment | "Farm operation type" |
| `agro:AgriculturalInput` (seed, fertilizer) | Cost structure | "Input financing" |
| `agro:SoilType` | Land valuation | "Farmland value assessment" |
| `agro:AgriculturalPractice` | Risk factors | "Conservation practices" |

### ❌ EXCLUDE (Not Finance-Relevant)
- Genomics/breeding
- Ornamental plants
- Non-core livestock
- Research methodologies

## Bridge Mappings (arden-bridge.ttl)

### High-Value Agriculture-Finance Bridges

| Mapping | AGRO Term | FIBO Term | Competency Question Supported |
|---------|-----------|-----------|------------------------------|
| **Crop as Collateral** | `agro:Crop` | `fibo-fbc-dae-dbt:Collateral` | "Stored grain inventory value" |
| **Yield to Cash Flow** | `agro:CropYield` | `fibo-fbc-pas-caa:CashFlow` | "Yield-tied mortgage payments" |
| **Farm as Business** | `agro:AgriculturalUnit` | `fibo-fnd-org-org:Organization` | "Farm Credit eligibility" |
| **Commodity Pricing** | `agro:Crop` | `fibo-der-drc-comm:Commodity` | "Wheat futures pricing" |
| **Land Valuation** | `agro:AgriculturalLand` | `fibo-fbc-dae-dbt:RealEstateAsset` | "Farmland mortgage structure" |

## Implementation Strategy

### Phase 1: Extract & Scope (Week 1)
1. Extract targeted FIBO terms (300K target)
2. Extract targeted AGRO terms (300K target)
3. Validate each module <500K

### Phase 2: Bridge Development (Week 2)
1. Implement 50-100 high-value bridges
2. Document each bridge with competency question
3. Validate semantic consistency

### Phase 3: Integration & Testing (Week 3)
1. Merge: core + ag + fin + bridge
2. Test ELK reasoning (<2min target)
3. Validate with pySHACL
4. Verify competency question coverage

**Success Criteria:**
- ✅ Total merged ontology <1.2MB
- ✅ ELK reasoning completes successfully
- ✅ All SHACL validations pass
- ✅ Each competency question answerable