#!/usr/bin/env python3
"""
Real-Time Commodity Price Integration for Arden v1.3.0
Fetches commodity prices from Yahoo Finance and generates RDF evidence
"""

import yfinance as yf
import requests
from datetime import datetime, timezone
from rdflib import Graph, Namespace, Literal, URIRef
from rdflib.namespace import RDF, RDFS, XSD
import json
import sys
from pathlib import Path

# Arden Ontology Namespaces
ARDEN = Namespace("https://arden.ag/ont/core#")
ARDEN_EVIDENCE = Namespace("https://arden.ag/ont/evidence#")
ARDEN_FIN = Namespace("https://arden.ag/ont/fin#")
QUDT = Namespace("http://qudt.org/schema/qudt/")
UNIT = Namespace("http://qudt.org/vocab/unit/")

# Agricultural Commodity Symbols for Yahoo Finance
COMMODITY_SYMBOLS = {
    'corn': 'ZC=F',      # Corn futures
    'soybeans': 'ZS=F',  # Soybean futures
    'wheat': 'ZW=F',     # Wheat futures
    'cattle': 'LE=F',    # Live cattle futures
    'hogs': 'HE=F',      # Lean hog futures
    'cotton': 'CT=F',    # Cotton futures
    'sugar': 'SB=F',     # Sugar futures
    'cocoa': 'CC=F',     # Cocoa futures
    'coffee': 'KC=F',    # Coffee futures
    'rice': 'ZR=F'       # Rough rice futures
}

# Unit mappings for different commodities
COMMODITY_UNITS = {
    'corn': UNIT.USD_PER_BU,      # Cents per bushel (convert to dollars)
    'soybeans': UNIT.USD_PER_BU,  # Cents per bushel
    'wheat': UNIT.USD_PER_BU,     # Cents per bushel
    'cattle': UNIT.USD_PER_CWT,   # Dollars per hundredweight
    'hogs': UNIT.USD_PER_CWT,     # Dollars per hundredweight
    'cotton': UNIT.USD_PER_LB,    # Cents per pound (convert to dollars)
    'sugar': UNIT.USD_PER_LB,     # Cents per pound
    'cocoa': UNIT.USD_PER_TON,    # Dollars per metric ton
    'coffee': UNIT.USD_PER_LB,    # Cents per pound
    'rice': UNIT.USD_PER_CWT      # Dollars per hundredweight
}

# Scale factors for unit conversion (Yahoo gives cents, we want dollars for some)
SCALE_FACTORS = {
    'corn': 0.01,      # Cents to dollars
    'soybeans': 0.01,  # Cents to dollars
    'wheat': 0.01,     # Cents to dollars
    'cattle': 1.0,     # Already in dollars
    'hogs': 1.0,       # Already in dollars
    'cotton': 0.01,    # Cents to dollars
    'sugar': 0.01,     # Cents to dollars
    'cocoa': 1.0,      # Already in dollars
    'coffee': 0.01,    # Cents to dollars
    'rice': 1.0        # Already in dollars
}

class CommodityPriceFetcher:
    """Fetches real-time commodity prices and generates RDF evidence"""

    def __init__(self):
        self.graph = Graph()
        self.bind_namespaces()

    def bind_namespaces(self):
        """Bind RDF namespaces"""
        self.graph.bind("arden", ARDEN)
        self.graph.bind("arden-evidence", ARDEN_EVIDENCE)
        self.graph.bind("arden-fin", ARDEN_FIN)
        self.graph.bind("qudt", QUDT)
        self.graph.bind("unit", UNIT)
        self.graph.bind("xsd", XSD)

    def fetch_commodity_prices(self, commodities=None):
        """
        Fetch current commodity prices from Yahoo Finance

        Args:
            commodities: List of commodity names to fetch, or None for all

        Returns:
            dict: Commodity prices with metadata
        """
        if commodities is None:
            commodities = list(COMMODITY_SYMBOLS.keys())

        prices = {}
        timestamp = datetime.now(timezone.utc)

        for commodity in commodities:
            if commodity not in COMMODITY_SYMBOLS:
                print(f"Warning: Unknown commodity {commodity}")
                continue

            symbol = COMMODITY_SYMBOLS[commodity]

            try:
                # Fetch ticker data
                ticker = yf.Ticker(symbol)
                info = ticker.info
                history = ticker.history(period="1d", interval="1m")

                if history.empty:
                    print(f"Warning: No price data for {commodity} ({symbol})")
                    continue

                # Get latest price
                latest_price = float(history['Close'].iloc[-1])

                # Apply scale factor for unit conversion
                scaled_price = latest_price * SCALE_FACTORS.get(commodity, 1.0)

                prices[commodity] = {
                    'symbol': symbol,
                    'price': scaled_price,
                    'timestamp': timestamp,
                    'currency': 'USD',
                    'unit': COMMODITY_UNITS[commodity],
                    'volume': float(history['Volume'].iloc[-1]) if 'Volume' in history else None,
                    'change': info.get('regularMarketChange', 0.0),
                    'change_percent': info.get('regularMarketChangePercent', 0.0)
                }

                print(f"✅ {commodity.title()}: ${scaled_price:.2f} ({symbol})")

            except Exception as e:
                print(f"❌ Error fetching {commodity} ({symbol}): {e}")
                continue

        return prices

    def generate_price_evidence_rdf(self, prices):
        """
        Generate RDF evidence for commodity prices

        Args:
            prices: Dictionary of price data from fetch_commodity_prices
        """

        for commodity, data in prices.items():
            # Create evidence instance
            evidence_uri = ARDEN_EVIDENCE[f"commodity_price_evidence_{commodity}_{int(data['timestamp'].timestamp())}"]

            # Evidence basic properties
            self.graph.add((evidence_uri, RDF.type, ARDEN_EVIDENCE.CommodityPriceEvidence))
            self.graph.add((evidence_uri, ARDEN_EVIDENCE.confidence, Literal(0.95, datatype=XSD.decimal)))
            self.graph.add((evidence_uri, ARDEN_EVIDENCE.authority, ARDEN_EVIDENCE.CommercialAuthority))
            self.graph.add((evidence_uri, ARDEN_EVIDENCE.wasGeneratedBy, ARDEN_EVIDENCE.YahooFinance))
            self.graph.add((evidence_uri, ARDEN_EVIDENCE.extractedOn, Literal(data['timestamp'], datatype=XSD.dateTime)))

            # Valid for 1 hour (commodity prices change frequently)
            valid_until = data['timestamp'].replace(hour=data['timestamp'].hour + 1)
            self.graph.add((evidence_uri, ARDEN_EVIDENCE.validUntil, Literal(valid_until, datatype=XSD.dateTime)))

            # Source information
            source_url = f"https://finance.yahoo.com/quote/{data['symbol']}"
            self.graph.add((evidence_uri, ARDEN_EVIDENCE.sourceURL, Literal(source_url, datatype=XSD.anyURI)))

            # Price quantity
            price_uri = ARDEN_FIN[f"commodity_price_{commodity}_{int(data['timestamp'].timestamp())}"]
            self.graph.add((price_uri, RDF.type, ARDEN_FIN.CommodityPrice))
            self.graph.add((price_uri, RDF.type, QUDT.Quantity))
            self.graph.add((price_uri, QUDT.numericValue, Literal(data['price'], datatype=XSD.decimal)))
            self.graph.add((price_uri, QUDT.unit, data['unit']))
            self.graph.add((price_uri, ARDEN.commodity, ARDEN[commodity.title()]))
            self.graph.add((price_uri, ARDEN.priceTimestamp, Literal(data['timestamp'], datatype=XSD.dateTime)))

            # Link evidence to price
            self.graph.add((evidence_uri, ARDEN_EVIDENCE.supports, price_uri))

            # Additional market data
            if data['volume']:
                self.graph.add((price_uri, ARDEN.tradingVolume, Literal(data['volume'], datatype=XSD.integer)))

            if data['change']:
                self.graph.add((price_uri, ARDEN.priceChange, Literal(data['change'], datatype=XSD.decimal)))

            if data['change_percent']:
                self.graph.add((price_uri, ARDEN.priceChangePercent, Literal(data['change_percent'], datatype=XSD.decimal)))

    def save_rdf(self, filename):
        """Save RDF graph to file"""
        filepath = Path(filename)
        self.graph.serialize(destination=str(filepath), format='turtle')
        print(f"💾 Saved commodity price evidence RDF to {filepath}")

    def get_turtle_string(self):
        """Return RDF graph as Turtle string"""
        return self.graph.serialize(format='turtle')

def main():
    """Main function for command-line usage"""
    import argparse

    parser = argparse.ArgumentParser(description='Fetch real-time commodity prices for Arden')
    parser.add_argument('--commodities', nargs='+', help='Specific commodities to fetch')
    parser.add_argument('--output', '-o', help='Output RDF file path')
    parser.add_argument('--format', default='turtle', choices=['turtle', 'json-ld', 'xml'], help='Output format')

    args = parser.parse_args()

    fetcher = CommodityPriceFetcher()

    print("🌽 Fetching real-time commodity prices...")
    prices = fetcher.fetch_commodity_prices(args.commodities)

    if not prices:
        print("❌ No price data retrieved")
        sys.exit(1)

    print(f"\n📊 Successfully fetched {len(prices)} commodity prices")

    # Generate RDF evidence
    fetcher.generate_price_evidence_rdf(prices)

    if args.output:
        fetcher.save_rdf(args.output)
    else:
        # Print to stdout
        print("\n" + "="*50)
        print("COMMODITY PRICE RDF EVIDENCE:")
        print("="*50)
        print(fetcher.get_turtle_string())

# Killer Question Integration Functions

def get_grain_futures_evidence(commodity='corn', max_age_hours=4):
    """
    Get grain futures evidence for KQ3 (grain inventory loan validation)

    Args:
        commodity: Commodity name ('corn', 'soybeans', 'wheat')
        max_age_hours: Maximum age of evidence in hours

    Returns:
        dict: Price evidence with validation metadata
    """
    fetcher = CommodityPriceFetcher()
    prices = fetcher.fetch_commodity_prices([commodity])

    if commodity not in prices:
        return None

    price_data = prices[commodity]
    evidence_age = (datetime.now(timezone.utc) - price_data['timestamp']).total_seconds() / 3600

    return {
        'commodity': commodity,
        'price': price_data['price'],
        'unit': str(price_data['unit']),
        'timestamp': price_data['timestamp'].isoformat(),
        'confidence': 0.95,
        'authority': 'Commercial',
        'source': 'Yahoo Finance',
        'evidence_age_hours': evidence_age,
        'is_current': evidence_age <= max_age_hours,
        'symbol': price_data['symbol'],
        'change_percent': price_data['change_percent']
    }

def validate_collateral_price_alignment(stored_quantity, commodity, futures_price=None):
    """
    Validate grain inventory collateral value against current futures prices (KQ3)

    Args:
        stored_quantity: Quantity of stored grain (bushels)
        commodity: Commodity type
        futures_price: Optional current price, will fetch if None

    Returns:
        dict: Validation results with recommendations
    """
    if futures_price is None:
        evidence = get_grain_futures_evidence(commodity)
        if not evidence:
            return {'error': f'Could not retrieve {commodity} price data'}
        futures_price = evidence['price']
    else:
        evidence = {'price': futures_price, 'confidence': 0.8}  # Lower confidence for provided price

    # Calculate market value
    market_value = stored_quantity * futures_price

    # Typical grain elevator margins and risk factors
    risk_discount = 0.15  # 15% discount for storage/handling/risk
    adjusted_value = market_value * (1 - risk_discount)

    # LTV thresholds for grain inventory loans
    max_ltv_conservative = 0.75  # Conservative lenders
    max_ltv_aggressive = 0.85    # Aggressive lenders

    max_loan_conservative = adjusted_value * max_ltv_conservative
    max_loan_aggressive = adjusted_value * max_ltv_aggressive

    return {
        'commodity': commodity,
        'stored_quantity': stored_quantity,
        'futures_price': futures_price,
        'market_value': market_value,
        'adjusted_value': adjusted_value,
        'risk_discount': risk_discount,
        'max_loan_conservative': max_loan_conservative,
        'max_loan_aggressive': max_loan_aggressive,
        'evidence': evidence,
        'recommendations': {
            'monitor_price_daily': True,
            'consider_hedging': evidence.get('change_percent', 0) < -5,  # Hedge if down >5%
            'review_ltv_if_price_drops': True
        }
    }

if __name__ == "__main__":
    main()