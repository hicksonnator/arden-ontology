# PostgreSQL to RDF Mapping Prompt for Arden Yahoo Finance Data

## Overview
You are an RDF mapping specialist for the Arden Agricultural Ontology. Your role is to create semantic mappings between the PostgreSQL market data schema (populated by the Yahoo Finance harvester) and the Arden ontology's RDF vocabulary. This enables SPARQL queries over the harvested market data while maintaining the performance benefits of PostgreSQL storage.

## Architecture Context
The Yahoo Finance harvester stores data in PostgreSQL tables under the `market` schema:
- `market.market_instruments` - Instrument definitions and metadata
- `market.market_quotes_daily` - OHLCV daily data
- `market.market_quotes_snapshot` - Real-time market snapshots
- `market.corporate_actions` - Dividends, splits, and other corporate events

Your task is to map this relational data to Arden ontology RDF triples for semantic reasoning.

## Core Ontology Prefixes
```turtle
@prefix arden: <https://arden.ag/ont/core#> .
@prefix arden-markets: <https://arden.ag/ont/markets#> .
@prefix arden-fin: <https://arden.ag/ont/fin#> .
@prefix arden-crops: <https://arden.ag/ont/crops#> .
@prefix bridge: <https://arden.ag/ont/bridge/markets#> .
@prefix sosa: <http://www.w3.org/ns/sosa/> .
@prefix time: <http://www.w3.org/2006/time#> .
@prefix qudt: <http://qudt.org/schema/qudt/> .
@prefix unit: <http://qudt.org/vocab/unit/> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix dct: <http://purl.org/dc/terms/> .
```

## PostgreSQL Schema Overview

### market.market_instruments
```sql
- instrument_id bigserial PK
- symbol text unique not null
- name text
- type text -- future | fx | index | equity | etf | rate
- exchange text
- currency text
- country text
- active boolean default true
- created_at timestamptz default now()
- updated_at timestamptz default now()
```

### market.market_quotes_daily
```sql
- instrument_id bigint FK → market_instruments
- date date not null
- open, high, low, close, adj_close double precision
- volume bigint
- source text default 'yahoo'
- PRIMARY KEY (instrument_id, date)
```

### market.market_quotes_snapshot
```sql
- instrument_id bigint FK
- ts timestamptz not null
- last, open, prev_close, day_high, day_low double precision
- volume bigint
- bid, ask, vwap double precision
- currency text
- market_state text
- fifty_two_wk_high, fifty_two_wk_low double precision
- trailing_pe, beta, dividend_yield double precision
- source text default 'yahoo'
- PRIMARY KEY (instrument_id, ts)
```

### market.corporate_actions
```sql
- instrument_id bigint FK
- action_type text -- dividend | split
- ex_date date
- record_date date
- pay_date date
- amount double precision
- ratio double precision
- currency text
- source text default 'yahoo'
- PRIMARY KEY (instrument_id, action_type, ex_date)
```

## Instrument Classification Mapping

### SQL to Ontology Class Mapping
Create SPARQL CONSTRUCT queries or R2RML mappings using these rules:

```sparql
# Agricultural Commodity Futures
CASE
  WHEN symbol = 'ZC=F' THEN arden-markets:CornFuture
  WHEN symbol = 'ZS=F' THEN arden-markets:SoybeanFuture
  WHEN symbol = 'ZW=F' THEN arden-markets:WheatFuture
  WHEN symbol = 'CT=F' THEN arden-markets:CottonFuture
  WHEN symbol IN ('LE=F', 'HE=F', 'GF=F') THEN arden-markets:LivestockFuture
  WHEN type = 'future' THEN arden-markets:Future
  WHEN type = 'fx' THEN arden-markets:ForexPair
  WHEN type = 'index' THEN arden-markets:Index
  WHEN type = 'equity' THEN arden-markets:Equity
  WHEN type = 'etf' THEN arden-markets:ETF
  WHEN type = 'rate' THEN arden-markets:RateInstrument
  ELSE arden-markets:MarketInstrument
END as ontology_class
```

### Exchange Mapping
```sql
CASE exchange
  WHEN 'CBOT' THEN arden-markets:CBOT
  WHEN 'CME' THEN arden-markets:CME
  WHEN 'NYSE' THEN arden-markets:NYSE
  WHEN 'NASDAQ' THEN arden-markets:NASDAQ
  ELSE arden-markets:UnknownExchange
END as exchange_uri
```

## R2RML Mapping Example

```turtle
# Market Instrument Mapping
:InstrumentTriplesMap a rr:TriplesMap ;
    rr:logicalTable [
        rr:sqlQuery """
            SELECT instrument_id, symbol, name, type, exchange, currency,
                   active, created_at, updated_at,
                   CASE
                     WHEN symbol = 'ZC=F' THEN 'CornFuture'
                     WHEN symbol = 'ZS=F' THEN 'SoybeanFuture'
                     WHEN symbol = 'ZW=F' THEN 'WheatFuture'
                     WHEN symbol = 'CT=F' THEN 'CottonFuture'
                     WHEN symbol IN ('LE=F', 'HE=F', 'GF=F') THEN 'LivestockFuture'
                     WHEN type = 'future' THEN 'Future'
                     WHEN type = 'equity' THEN 'Equity'
                     WHEN type = 'etf' THEN 'ETF'
                     ELSE 'MarketInstrument'
                   END as ont_class
            FROM market.market_instruments
        """
    ] ;
    rr:subjectMap [
        rr:template "https://data.arden.ag/instrument/{instrument_id}" ;
        rr:class arden-markets:MarketInstrument
    ] ;
    # Dynamic class assignment based on instrument type
    rr:predicateObjectMap [
        rr:predicate rdf:type ;
        rr:objectMap [
            rr:template "https://arden.ag/ont/markets#{ont_class}"
        ]
    ] ;
    # Basic properties
    rr:predicateObjectMap [
        rr:predicate arden-markets:hasCanonicalSymbol ;
        rr:objectMap [
            rr:template "https://data.arden.ag/symbol/{symbol}" ;
            rr:termType rr:IRI
        ]
    ] ;
    rr:predicateObjectMap [
        rr:predicate arden-markets:isActive ;
        rr:objectMap [ rr:column "active" ; rr:datatype xsd:boolean ]
    ] ;
    rr:predicateObjectMap [
        rr:predicate dct:created ;
        rr:objectMap [ rr:column "created_at" ; rr:datatype xsd:dateTime ]
    ] .

# Symbol Mapping
:SymbolTriplesMap a rr:TriplesMap ;
    rr:logicalTable [ rr:tableName "market.market_instruments" ] ;
    rr:subjectMap [
        rr:template "https://data.arden.ag/symbol/{symbol}"
    ] ;
    rr:predicateObjectMap [
        rr:predicate rdf:type ;
        rr:object arden-markets:MarketSymbol
    ] ;
    rr:predicateObjectMap [
        rr:predicate arden-markets:symbolValue ;
        rr:objectMap [ rr:column "symbol" ]
    ] .

# OHLCV Observations Mapping
:OHLCVTriplesMap a rr:TriplesMap ;
    rr:logicalTable [
        rr:sqlQuery """
            SELECT i.instrument_id, i.symbol, i.type, d.date,
                   d.open, d.high, d.low, d.close, d.adj_close, d.volume,
                   d.source
            FROM market.market_quotes_daily d
            JOIN market.market_instruments i ON d.instrument_id = i.instrument_id
            WHERE d.date >= CURRENT_DATE - INTERVAL '30 days'
        """
    ] ;
    rr:subjectMap [
        rr:template "https://data.arden.ag/ohlcv/{instrument_id}/{date}"
    ] ;
    rr:predicateObjectMap [
        rr:predicate rdf:type ;
        rr:object arden-markets:OHLCVObservation
    ] ;
    rr:predicateObjectMap [
        rr:predicate arden-markets:observesInstrument ;
        rr:objectMap [
            rr:template "https://data.arden.ag/instrument/{instrument_id}" ;
            rr:termType rr:IRI
        ]
    ] ;
    rr:predicateObjectMap [
        rr:predicate arden-markets:tradingDate ;
        rr:objectMap [ rr:column "date" ; rr:datatype xsd:date ]
    ] ;
    rr:predicateObjectMap [
        rr:predicate arden-markets:openPrice ;
        rr:objectMap [ rr:column "open" ; rr:datatype xsd:decimal ]
    ] ;
    rr:predicateObjectMap [
        rr:predicate arden-markets:highPrice ;
        rr:objectMap [ rr:column "high" ; rr:datatype xsd:decimal ]
    ] ;
    rr:predicateObjectMap [
        rr:predicate arden-markets:lowPrice ;
        rr:objectMap [ rr:column "low" ; rr:datatype xsd:decimal ]
    ] ;
    rr:predicateObjectMap [
        rr:predicate arden-markets:closePrice ;
        rr:objectMap [ rr:column "close" ; rr:datatype xsd:decimal ]
    ] ;
    rr:predicateObjectMap [
        rr:predicate arden-markets:adjustedClosePrice ;
        rr:objectMap [ rr:column "adj_close" ; rr:datatype xsd:decimal ]
    ] ;
    rr:predicateObjectMap [
        rr:predicate arden-markets:volume ;
        rr:objectMap [ rr:column "volume" ; rr:datatype xsd:integer ]
    ] ;
    rr:predicateObjectMap [
        rr:predicate arden-markets:dataSource ;
        rr:objectMap [ rr:column "source" ]
    ] .
```

## Agricultural Commodity Bridge Mappings

```sparql
# SPARQL CONSTRUCT for Agricultural Bridges
CONSTRUCT {
    ?instrument arden-markets:representsCommodity ?commodity .
    ?ohlcv arden-markets:affectsCollateralValue ?collateral .
    ?ohlcv arden-markets:drivesCashFlowProjection ?cashflow .
}
WHERE {
    # From PostgreSQL via R2RML
    ?instrument a ?instrumentType ;
        arden-markets:hasCanonicalSymbol/arden-markets:symbolValue ?symbol .
    ?ohlcv arden-markets:observesInstrument ?instrument .

    # Agricultural commodity mappings
    VALUES (?symbol ?commodity ?instrumentType) {
        ("ZC=F" arden-crops:Corn arden-markets:CornFuture)
        ("ZS=F" arden-crops:Soybean arden-markets:SoybeanFuture)
        ("ZW=F" arden-crops:Wheat arden-markets:WheatFuture)
        ("CT=F" arden-crops:Cotton arden-markets:CottonFuture)
    }

    # Connect to agricultural finance (these would be loaded separately)
    OPTIONAL {
        ?collateral a arden-fin:CollateralAsset ;
            arden-fin:representsAsset ?commodity .
    }
    OPTIONAL {
        ?cashflow a arden-fin:CashFlowProjection ;
            arden-fin:basedOnCommodity ?commodity .
    }
}
```

## Snapshot Data Mapping

```turtle
:SnapshotTriplesMap a rr:TriplesMap ;
    rr:logicalTable [
        rr:sqlQuery """
            SELECT instrument_id, ts, last, bid, ask, prev_close,
                   day_high, day_low, volume, market_state, currency,
                   fifty_two_wk_high, fifty_two_wk_low, trailing_pe,
                   beta, dividend_yield, source
            FROM market.market_quotes_snapshot s
            WHERE s.ts >= NOW() - INTERVAL '1 hour'
        """
    ] ;
    rr:subjectMap [
        rr:template "https://data.arden.ag/snapshot/{instrument_id}/{ts}"
    ] ;
    rr:predicateObjectMap [
        rr:predicate rdf:type ;
        rr:object arden-markets:SnapshotObservation
    ] ;
    rr:predicateObjectMap [
        rr:predicate arden-markets:observesInstrument ;
        rr:objectMap [
            rr:template "https://data.arden.ag/instrument/{instrument_id}" ;
            rr:termType rr:IRI
        ]
    ] ;
    rr:predicateObjectMap [
        rr:predicate sosa:resultTime ;
        rr:objectMap [ rr:column "ts" ; rr:datatype xsd:dateTime ]
    ] ;
    rr:predicateObjectMap [
        rr:predicate arden-markets:lastPrice ;
        rr:objectMap [ rr:column "last" ; rr:datatype xsd:decimal ]
    ] ;
    rr:predicateObjectMap [
        rr:predicate arden-markets:bidPrice ;
        rr:objectMap [ rr:column "bid" ; rr:datatype xsd:decimal ]
    ] ;
    rr:predicateObjectMap [
        rr:predicate arden-markets:askPrice ;
        rr:objectMap [ rr:column "ask" ; rr:datatype xsd:decimal ]
    ] ;
    rr:predicateObjectMap [
        rr:predicate arden-markets:marketState ;
        rr:objectMap [ rr:column "market_state" ]
    ] .
```

## Corporate Actions Mapping

```turtle
:CorporateActionsTriplesMap a rr:TriplesMap ;
    rr:logicalTable [
        rr:sqlQuery """
            SELECT instrument_id, action_type, ex_date, record_date,
                   pay_date, amount, ratio, currency, source,
                   CASE action_type
                     WHEN 'dividend' THEN 'Dividend'
                     WHEN 'split' THEN 'StockSplit'
                     ELSE 'CorporateAction'
                   END as action_class
            FROM market.corporate_actions
        """
    ] ;
    rr:subjectMap [
        rr:template "https://data.arden.ag/action/{instrument_id}/{action_type}/{ex_date}"
    ] ;
    rr:predicateObjectMap [
        rr:predicate rdf:type ;
        rr:objectMap [
            rr:template "https://arden.ag/ont/markets#{action_class}"
        ]
    ] ;
    rr:predicateObjectMap [
        rr:predicate arden-markets:affectsInstrument ;
        rr:objectMap [
            rr:template "https://data.arden.ag/instrument/{instrument_id}" ;
            rr:termType rr:IRI
        ]
    ] ;
    rr:predicateObjectMap [
        rr:predicate arden-markets:exDate ;
        rr:objectMap [ rr:column "ex_date" ; rr:datatype xsd:date ]
    ] ;
    rr:predicateObjectMap [
        rr:predicate arden-markets:dividendAmount ;
        rr:objectMap [
            rr:column "amount" ;
            rr:datatype xsd:decimal ;
            rr:condition "action_type = 'dividend'"
        ]
    ] ;
    rr:predicateObjectMap [
        rr:predicate arden-markets:splitRatio ;
        rr:objectMap [
            rr:column "ratio" ;
            rr:datatype xsd:decimal ;
            rr:condition "action_type = 'split'"
        ]
    ] .
```

## SPARQL Query Examples

Once mapped, you can query the data semantically:

### Killer Competency Questions
```sparql
# "How do wheat futures prices affect grain storage collateral?"
PREFIX arden-markets: <https://arden.ag/ont/markets#>
PREFIX arden-crops: <https://arden.ag/ont/crops#>
PREFIX arden-fin: <https://arden.ag/ont/fin#>

SELECT ?date ?wheatPrice ?collateralValue WHERE {
    # Get wheat futures data
    ?wheatFuture a arden-markets:WheatFuture ;
        arden-markets:hasCanonicalSymbol/arden-markets:symbolValue "ZW=F" .

    ?ohlcv arden-markets:observesInstrument ?wheatFuture ;
        arden-markets:tradingDate ?date ;
        arden-markets:closePrice ?wheatPrice .

    # Connect to collateral impact
    ?ohlcv arden-markets:affectsCollateralValue ?collateral .
    ?collateral arden-fin:hasValue ?collateralValue .

    FILTER(?date >= "2025-09-01"^^xsd:date)
}
ORDER BY DESC(?date)
```

### Agricultural Portfolio Analysis
```sparql
# Get all agricultural commodity positions
SELECT ?commodity ?symbol ?currentPrice ?volume WHERE {
    ?instrument a ?futureType ;
        arden-markets:hasCanonicalSymbol/arden-markets:symbolValue ?symbol ;
        arden-markets:representsCommodity ?commodity .

    ?snapshot arden-markets:observesInstrument ?instrument ;
        arden-markets:lastPrice ?currentPrice ;
        arden-markets:volume ?volume .

    FILTER(?futureType IN (
        arden-markets:CornFuture,
        arden-markets:SoybeanFuture,
        arden-markets:WheatFuture,
        arden-markets:CottonFuture
    ))

    # Get latest snapshot only
    {
        SELECT ?instrument (MAX(?ts) as ?maxTs) WHERE {
            ?snap arden-markets:observesInstrument ?instrument ;
                sosa:resultTime ?ts .
        }
        GROUP BY ?instrument
    }
    ?snapshot sosa:resultTime ?maxTs .
}
```

## Implementation Options

### Option 1: R2RML with Ontop
- Use Ontop or similar R2RML engine
- Provides SPARQL endpoint over PostgreSQL
- Automatic query rewriting to SQL
- Best performance for complex queries

### Option 2: Custom SPARQL Endpoint
- Build custom endpoint using your Python stack
- Direct SQL-to-RDF translation
- Can optimize for specific query patterns
- Full control over mapping logic

### Option 3: ETL to RDF Store
- Periodic export from PostgreSQL to RDF store (Blazegraph, GraphDB)
- Use ontology-compliant RDF generation
- Enables full semantic reasoning
- Higher latency but full SPARQL support

## Data Quality and Validation

Map PostgreSQL constraints to SHACL validation:
```turtle
# Validate price consistency from mapped data
:PriceConsistencyShape a sh:NodeShape ;
    sh:targetClass arden-markets:OHLCVObservation ;
    sh:sparql [
        sh:message "High price must be >= open price (from PostgreSQL data)" ;
        sh:select """
            SELECT $this WHERE {
                $this arden-markets:highPrice ?high ;
                      arden-markets:openPrice ?open .
                FILTER(?high < ?open)
            }
        """
    ] .
```

## Performance Considerations

- **Indexing**: Ensure PostgreSQL indexes support common SPARQL patterns
- **Caching**: Cache frequent ontology mappings in memory
- **Pagination**: Implement LIMIT/OFFSET for large result sets
- **Materialization**: Pre-compute common agricultural bridge connections

This mapping approach preserves your efficient PostgreSQL storage while enabling sophisticated semantic queries and reasoning over the market data through the Arden ontology.