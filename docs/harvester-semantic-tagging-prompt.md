# Harvester Semantic Tagging Integration Prompt

## Overview
You are integrating semantic tagging capabilities into the Arden Yahoo Finance harvester. Your role is to ensure that all harvested market data is properly tagged with semantic metadata using the **existing Arden ontology infrastructure**. This enables sophisticated agricultural-financial reasoning while maintaining data integrity and performance.

## Core Principles

### 🚫 **NEVER CREATE ONTOLOGY CONCEPTS**
- **Use existing vocabulary only** - The Arden ontology is production-deployed and complete
- **Query the ontology** to find appropriate classes and properties
- **Flag missing concepts** for ontology team review rather than creating new ones
- **Fail gracefully** if no appropriate concept exists

### 🔄 **Always Use Latest Ontology Version**
- **Check for updates** at harvester startup and periodically during operation
- **Download automatically** using authenticated Git CLI access
- **Validate compatibility** before applying ontology updates
- **Rollback capability** if new version causes issues

## Ontology Version Management

### Startup Version Check
```python
import subprocess
import json
from datetime import datetime, timedelta

class OntologyVersionManager:
    def __init__(self, repo_url: str, local_path: str, check_interval_hours: int = 6):
        self.repo_url = repo_url
        self.local_path = local_path
        self.check_interval = timedelta(hours=check_interval_hours)
        self.last_check = None
        self.current_version = None

    def check_for_updates(self) -> bool:
        """Check if new ontology version is available on GitHub"""
        if (self.last_check and
            datetime.now() - self.last_check < self.check_interval):
            return False

        try:
            # Get latest release info from GitHub
            result = subprocess.run([
                'gh', 'release', 'view', '--repo', self.repo_url,
                '--json', 'tagName,publishedAt'
            ], capture_output=True, text=True, check=True)

            release_info = json.loads(result.stdout)
            latest_version = release_info['tagName']

            self.last_check = datetime.now()

            # Compare with current version
            if latest_version != self.current_version:
                logger.info(f"New ontology version available: {latest_version}")
                return True

        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to check ontology version: {e}")

        return False

    def download_update(self, version: str) -> bool:
        """Download and extract new ontology version"""
        try:
            # Download release archive
            subprocess.run([
                'gh', 'release', 'download', version,
                '--repo', self.repo_url,
                '--pattern', 'arden-ontology-production-*.tar.gz',
                '--dir', f'{self.local_path}/temp'
            ], check=True)

            # Extract and validate
            archive_path = self._find_archive(f'{self.local_path}/temp')
            if self._extract_and_validate(archive_path):
                self.current_version = version
                logger.info(f"Successfully updated to ontology {version}")
                return True

        except Exception as e:
            logger.error(f"Failed to download ontology update: {e}")

        return False
```

### Authentication Setup
```bash
# One-time setup for harvester authentication
gh auth login --with-token < ~/.github/token
gh auth setup-git

# Verify access to ontology repository
gh repo view hicksonnator/arden-ontology
```

## Database Schema for Semantic Tags

### Core Tables
```sql
-- Ontology metadata and versioning
CREATE TABLE IF NOT EXISTS semantic.ontology_versions (
    version_id SERIAL PRIMARY KEY,
    version_tag TEXT UNIQUE NOT NULL,
    download_date TIMESTAMPTZ DEFAULT NOW(),
    ontology_size_bytes BIGINT,
    validation_status TEXT CHECK (validation_status IN ('pending', 'valid', 'invalid')),
    is_active BOOLEAN DEFAULT FALSE,
    rollback_available BOOLEAN DEFAULT TRUE
);

-- Semantic concept registry (populated from ontology)
CREATE TABLE IF NOT EXISTS semantic.ontology_concepts (
    concept_id SERIAL PRIMARY KEY,
    version_id INTEGER REFERENCES semantic.ontology_versions(version_id),
    concept_uri TEXT NOT NULL,
    concept_type TEXT, -- class, property, individual
    parent_concept_uri TEXT,
    label TEXT,
    definition TEXT,
    domain_area TEXT, -- markets, agriculture, finance, etc.
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(version_id, concept_uri)
);

-- Semantic tags applied to market data
CREATE TABLE IF NOT EXISTS semantic.market_data_tags (
    tag_id BIGSERIAL PRIMARY KEY,
    -- Link to market data
    instrument_id BIGINT, -- FK to market.market_instruments
    ohlcv_date DATE, -- For daily data
    snapshot_ts TIMESTAMPTZ, -- For snapshot data
    corporate_action_id BIGINT, -- For corporate actions

    -- Semantic information
    concept_uri TEXT NOT NULL,
    confidence_score DECIMAL(3,2) CHECK (confidence_score BETWEEN 0.0 AND 1.0),
    evidence_text TEXT,
    tag_scope TEXT CHECK (tag_scope IN ('instrument', 'ohlcv', 'snapshot', 'corporate_action')),

    -- Agricultural-financial bridges
    bridge_connections JSONB, -- Stores related concept URIs and relationships

    -- Metadata
    tagged_at TIMESTAMPTZ DEFAULT NOW(),
    ontology_version TEXT NOT NULL,
    tagger_model TEXT, -- claude-sonnet-4, etc.

    -- Constraints
    CHECK (
        (instrument_id IS NOT NULL AND ohlcv_date IS NULL AND snapshot_ts IS NULL AND corporate_action_id IS NULL) OR
        (instrument_id IS NOT NULL AND ohlcv_date IS NOT NULL AND snapshot_ts IS NULL AND corporate_action_id IS NULL) OR
        (instrument_id IS NOT NULL AND ohlcv_date IS NULL AND snapshot_ts IS NOT NULL AND corporate_action_id IS NULL) OR
        (corporate_action_id IS NOT NULL AND instrument_id IS NULL AND ohlcv_date IS NULL AND snapshot_ts IS NULL)
    )
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_market_data_tags_instrument ON semantic.market_data_tags(instrument_id);
CREATE INDEX IF NOT EXISTS idx_market_data_tags_concept ON semantic.market_data_tags(concept_uri);
CREATE INDEX IF NOT EXISTS idx_market_data_tags_confidence ON semantic.market_data_tags(confidence_score);
CREATE INDEX IF NOT EXISTS idx_market_data_tags_bridge_gin ON semantic.market_data_tags USING GIN(bridge_connections);

-- Tagging quality metrics
CREATE TABLE IF NOT EXISTS semantic.tagging_metrics (
    metric_id SERIAL PRIMARY KEY,
    harvester_run_id BIGINT, -- Link to harvester execution
    instruments_processed INTEGER,
    concepts_applied INTEGER,
    avg_confidence_score DECIMAL(3,2),
    low_confidence_count INTEGER, -- < 0.7
    bridge_connections_created INTEGER,
    processing_time_ms INTEGER,
    ontology_version TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

## Semantic Tagging Implementation

### Market Instrument Tagging
```python
class MarketDataTagger:
    def __init__(self, ontology_manager: OntologyVersionManager, db_conn):
        self.ontology = ontology_manager
        self.db = db_conn
        self.concept_cache = {}

    def tag_market_instrument(self, instrument: dict) -> List[dict]:
        """Apply semantic tags to market instrument"""
        tags = []

        # Get ontology class for instrument type and symbol
        instrument_class = self._get_instrument_class(
            symbol=instrument['symbol'],
            instrument_type=instrument['type']
        )

        if instrument_class:
            tag = {
                'concept_uri': instrument_class,
                'confidence_score': 0.95,
                'evidence_text': f"Instrument {instrument['symbol']} of type {instrument['type']}",
                'tag_scope': 'instrument',
                'bridge_connections': self._get_bridge_connections(instrument_class)
            }
            tags.append(tag)

        # Tag agricultural commodity connections
        if self._is_agricultural_commodity(instrument['symbol']):
            commodity_tags = self._tag_agricultural_commodity(instrument)
            tags.extend(commodity_tags)

        return tags

    def _get_instrument_class(self, symbol: str, instrument_type: str) -> Optional[str]:
        """Get ontology class for market instrument - NEVER create new classes"""

        # Agricultural futures mapping (from existing ontology)
        agricultural_futures = {
            'ZC=F': 'arden-markets:CornFuture',
            'ZS=F': 'arden-markets:SoybeanFuture',
            'ZW=F': 'arden-markets:WheatFuture',
            'CT=F': 'arden-markets:CottonFuture',
            'LE=F': 'arden-markets:LivestockFuture',
            'HE=F': 'arden-markets:LivestockFuture',
            'GF=F': 'arden-markets:LivestockFuture'
        }

        # Check exact symbol match first
        if symbol in agricultural_futures:
            return agricultural_futures[symbol]

        # Fall back to generic type mapping
        type_mapping = {
            'future': 'arden-markets:Future',
            'equity': 'arden-markets:Equity',
            'etf': 'arden-markets:ETF',
            'fx': 'arden-markets:ForexPair',
            'index': 'arden-markets:Index',
            'rate': 'arden-markets:RateInstrument'
        }

        ontology_class = type_mapping.get(instrument_type, 'arden-markets:MarketInstrument')

        # Validate class exists in ontology (CRITICAL)
        if not self._validate_concept_exists(ontology_class):
            logger.error(f"Ontology class {ontology_class} not found - flagging for review")
            return None

        return ontology_class

    def _get_bridge_connections(self, instrument_class: str) -> dict:
        """Get agricultural-financial bridge connections"""
        bridges = {}

        # Agricultural commodity bridges (from arden-bridge-markets.ttl)
        commodity_bridges = {
            'arden-markets:CornFuture': {
                'represents_commodity': 'arden-crops:Corn',
                'affects_collateral': 'arden-fin:GrainBinCollateral',
                'drives_cashflow': 'arden-fin:CornRevenueProjection'
            },
            'arden-markets:SoybeanFuture': {
                'represents_commodity': 'arden-crops:Soybean',
                'affects_collateral': 'arden-fin:GrainBinCollateral',
                'drives_cashflow': 'arden-fin:SoybeanRevenueProjection'
            },
            'arden-markets:WheatFuture': {
                'represents_commodity': 'arden-crops:Wheat',
                'affects_collateral': 'arden-fin:GrainBinCollateral',
                'drives_cashflow': 'arden-fin:WheatRevenueProjection'
            }
        }

        return commodity_bridges.get(instrument_class, {})
```

### OHLCV Data Tagging
```python
def tag_ohlcv_observation(self, ohlcv: dict, instrument: dict) -> List[dict]:
    """Apply semantic tags to OHLCV market data"""
    tags = []

    # Main OHLCV observation tag
    base_tag = {
        'concept_uri': 'arden-markets:OHLCVObservation',
        'confidence_score': 1.0,
        'evidence_text': f"Daily OHLCV data for {instrument['symbol']} on {ohlcv['date']}",
        'tag_scope': 'ohlcv',
        'bridge_connections': {}
    }

    # Add agricultural impact bridges for commodity futures
    if self._is_agricultural_commodity(instrument['symbol']):
        bridge_connections = self._get_agricultural_impact_bridges(
            instrument['symbol'],
            ohlcv['close']
        )
        base_tag['bridge_connections'] = bridge_connections

    tags.append(base_tag)

    # Data quality tags based on validation
    if self._has_data_quality_issues(ohlcv):
        quality_tag = {
            'concept_uri': 'arden-markets:DataQualityIssue',
            'confidence_score': 0.8,
            'evidence_text': self._describe_quality_issues(ohlcv),
            'tag_scope': 'ohlcv'
        }
        tags.append(quality_tag)

    return tags

def _get_agricultural_impact_bridges(self, symbol: str, price: float) -> dict:
    """Get agricultural-financial impact connections"""
    bridges = {}

    # Price impact on collateral (for killer competency questions)
    if symbol == 'ZW=F':  # Wheat futures
        bridges['affects_collateral_value'] = [
            'arden-fin:WheatInventoryCollateral',
            'arden-fin:GrainBinCollateral'
        ]
        bridges['drives_cash_flow_projection'] = [
            'arden-fin:WheatRevenueProjection'
        ]

    elif symbol == 'ZC=F':  # Corn futures
        bridges['affects_collateral_value'] = [
            'arden-fin:CornInventoryCollateral',
            'arden-fin:GrainBinCollateral'
        ]
        bridges['drives_cash_flow_projection'] = [
            'arden-fin:CornRevenueProjection'
        ]

    # Add price threshold alerts for risk assessment
    if self._exceeds_volatility_threshold(symbol, price):
        bridges['contributes_to_market_risk'] = [
            'arden-fin:CommodityVolatilityRisk'
        ]

    return bridges
```

## Database Storage Patterns

### Tag Storage
```python
def store_semantic_tags(self, tags: List[dict], data_reference: dict):
    """Store semantic tags in database with full traceability"""

    with self.db.transaction():
        for tag in tags:
            # Validate concept exists in current ontology version
            if not self._validate_concept_exists(tag['concept_uri']):
                logger.warning(f"Skipping unknown concept: {tag['concept_uri']}")
                continue

            # Store tag with complete metadata
            tag_id = self.db.execute("""
                INSERT INTO semantic.market_data_tags (
                    instrument_id, ohlcv_date, snapshot_ts, corporate_action_id,
                    concept_uri, confidence_score, evidence_text, tag_scope,
                    bridge_connections, ontology_version, tagger_model
                ) VALUES (
                    %(instrument_id)s, %(ohlcv_date)s, %(snapshot_ts)s, %(corporate_action_id)s,
                    %(concept_uri)s, %(confidence_score)s, %(evidence_text)s, %(tag_scope)s,
                    %(bridge_connections)s, %(ontology_version)s, %(tagger_model)s
                ) RETURNING tag_id
            """, {
                **data_reference,
                **tag,
                'bridge_connections': json.dumps(tag.get('bridge_connections', {})),
                'ontology_version': self.ontology.current_version,
                'tagger_model': 'claude-sonnet-4'
            }).scalar()

            logger.info(f"Stored semantic tag {tag_id}: {tag['concept_uri']}")
```

## Quality Assurance and Validation

### Runtime Validation
```python
class SemanticTagValidator:
    def __init__(self, ontology_manager):
        self.ontology = ontology_manager

    def validate_tags(self, tags: List[dict]) -> Tuple[List[dict], List[str]]:
        """Validate semantic tags against ontology"""
        valid_tags = []
        errors = []

        for tag in tags:
            # Check concept exists
            if not self._concept_exists(tag['concept_uri']):
                errors.append(f"Unknown concept: {tag['concept_uri']}")
                continue

            # Check confidence threshold
            if tag['confidence_score'] < 0.5:
                errors.append(f"Low confidence ({tag['confidence_score']}) for {tag['concept_uri']}")
                continue

            # Validate bridge connections
            bridge_errors = self._validate_bridge_connections(tag.get('bridge_connections', {}))
            if bridge_errors:
                errors.extend(bridge_errors)
                continue

            valid_tags.append(tag)

        return valid_tags, errors

    def _concept_exists(self, concept_uri: str) -> bool:
        """Check if concept exists in current ontology version"""
        return self.db.execute("""
            SELECT 1 FROM semantic.ontology_concepts
            WHERE concept_uri = %s
            AND version_id = (
                SELECT version_id FROM semantic.ontology_versions
                WHERE is_active = true
            )
        """, [concept_uri]).fetchone() is not None
```

## Monitoring and Metrics

### Tagging Quality Dashboard
```python
def generate_tagging_metrics(harvester_run_id: int) -> dict:
    """Generate quality metrics for semantic tagging"""

    metrics = db.execute("""
        SELECT
            COUNT(*) as total_tags,
            AVG(confidence_score) as avg_confidence,
            COUNT(*) FILTER (WHERE confidence_score < 0.7) as low_confidence_count,
            COUNT(*) FILTER (WHERE bridge_connections != '{}') as bridge_tags_count,
            COUNT(DISTINCT concept_uri) as unique_concepts_used,
            COUNT(DISTINCT instrument_id) as instruments_tagged
        FROM semantic.market_data_tags
        WHERE tagged_at >= (
            SELECT started_at FROM harvester_runs WHERE run_id = %s
        )
    """, [harvester_run_id]).fetchone()

    # Store metrics
    db.execute("""
        INSERT INTO semantic.tagging_metrics (
            harvester_run_id, instruments_processed, concepts_applied,
            avg_confidence_score, low_confidence_count, bridge_connections_created,
            ontology_version
        ) VALUES (%s, %s, %s, %s, %s, %s, %s)
    """, [
        harvester_run_id,
        metrics['instruments_tagged'],
        metrics['total_tags'],
        metrics['avg_confidence'],
        metrics['low_confidence_count'],
        metrics['bridge_tags_count'],
        ontology_manager.current_version
    ])

    return metrics
```

## Error Handling and Fallbacks

### Ontology Update Failures
```python
def handle_ontology_update_failure(self, error: Exception):
    """Handle ontology update failures gracefully"""
    logger.error(f"Ontology update failed: {error}")

    # Continue with current version
    if self.current_version:
        logger.info(f"Continuing with ontology version {self.current_version}")
        return True

    # If no ontology available, fail harvester startup
    logger.critical("No ontology version available - cannot start harvester")
    raise RuntimeError("Ontology required for semantic tagging")

def handle_missing_concepts(self, concept_uri: str, context: dict):
    """Handle cases where expected ontology concepts are missing"""

    # Log for ontology team review
    logger.warning(f"Missing ontology concept: {concept_uri} in context: {context}")

    # Store for analysis
    db.execute("""
        INSERT INTO semantic.missing_concepts (
            concept_uri, context_data, requested_at, ontology_version
        ) VALUES (%s, %s, %s, %s)
    """, [concept_uri, json.dumps(context), datetime.now(), self.current_version])

    # Use parent concept if available
    parent_concept = self._find_parent_concept(concept_uri)
    if parent_concept:
        logger.info(f"Using parent concept {parent_concept} for {concept_uri}")
        return parent_concept

    return None
```

## Success Criteria

The harvester semantic tagging is successful when:
- ✅ **Always uses existing ontology** - No new concepts created
- ✅ **Automatic version management** - Downloads updates via authenticated Git CLI
- ✅ **Complete agricultural-financial bridges** - Enables killer competency questions
- ✅ **Database integration** - Semantic tags stored with full traceability
- ✅ **Quality validation** - Confidence scoring and concept verification
- ✅ **Performance monitoring** - Metrics tracked and reported
- ✅ **Graceful error handling** - Continues operation despite ontology issues
- ✅ **Audit trail** - Complete lineage from data to semantic tags

This integration transforms the Yahoo Finance harvester into a semantically-aware system that creates rich, queryable knowledge graphs supporting sophisticated agricultural-financial decision making.