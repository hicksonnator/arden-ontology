#!/usr/bin/env python3
"""
Minimal CSV-to-RDF ingest template for Arden Ontology
Adapt this script for your specific data sources and ETL pipeline.
"""

import csv
import sys
from rdflib import Graph, Namespace, Literal, URIRef
from rdflib.namespace import RDF, XSD

# Define namespaces
ARDEN = Namespace("https://arden.ag/ont/core#")
ARDEN_AG = Namespace("https://arden.ag/ont/ag#")
SOSA = Namespace("http://www.w3.org/ns/sosa/")
QUDT = Namespace("http://qudt.org/schema/qudt/")
UNIT = Namespace("http://qudt.org/vocab/unit/")
DATA = Namespace("https://arden.ag/data/")

def csv_to_rdf_yield_observations(csv_file_path, output_file_path):
    """
    Convert CSV with yield data to RDF using Arden patterns.
    Enhanced with ETL guardrails and validation.

    Expected CSV format:
    parcel_id,fips,obs_time,yield_bu_ac
    42,19153,2023-10-01T00:00:00Z,185.2
    """

    # Create RDF graph
    g = Graph()

    # Bind namespaces
    g.bind("arden", ARDEN)
    g.bind("arden-ag", ARDEN_AG)
    g.bind("sosa", SOSA)
    g.bind("qudt", QUDT)
    g.bind("unit", UNIT)
    g.bind("data", DATA)

    # ETL Guardrails
    seen_combinations = set()  # Track (parcel_id, obs_time) for duplicate detection
    validation_errors = []
    processed_rows = 0

    # Read CSV and convert to RDF
    with open(csv_file_path, 'r') as csvfile:
        reader = csv.DictReader(csvfile)

        for row_num, row in enumerate(reader, 1):
            try:
                # Extract values
                parcel_id = row['parcel_id'].strip()
                fips = row['fips'].strip()
                obs_time = row['obs_time'].strip()
                yield_raw = row['yield_bu_ac'].strip()

                # Data validation
                if not parcel_id or not fips or not obs_time or not yield_raw:
                    validation_errors.append(f"Row {row_num}: Missing required fields")
                    continue

                # Duplicate detection
                key = (parcel_id, obs_time)
                if key in seen_combinations:
                    validation_errors.append(f"Row {row_num}: Duplicate (parcel_id, obs_time): {key}")
                    continue
                seen_combinations.add(key)

                # Unit coercion and normalization
                yield_value = float(yield_raw)

                # Validate yield range (corn: 0-500 bu/acre reasonable)
                if yield_value < 0 or yield_value > 500:
                    validation_errors.append(f"Row {row_num}: Yield {yield_value} outside reasonable range (0-500)")
                    continue

                # Normalize units to QUDT canonical form
                unit_iri = UNIT.BushelPerAcre  # Default for this template

                # Create stable URIs using source system keys
                parcel_uri = DATA[f"parcel/{parcel_id}"]
                county_uri = DATA[f"county/{fips}"]
                obs_uri = DATA[f"yield-obs/{parcel_id}-{obs_time.replace(':', '-')}"]
                result_uri = DATA[f"yield-result/{parcel_id}-{obs_time.replace(':', '-')}"]

                # Add parcel triples
                g.add((parcel_uri, RDF.type, ARDEN.FarmParcel))
                g.add((parcel_uri, ARDEN.locatedInCounty, county_uri))
                g.add((parcel_uri, ARDEN.sourceSystemId, Literal(f"PARCEL_{parcel_id}")))

                # Add observation triples
                g.add((obs_uri, RDF.type, ARDEN_AG.YieldObservation))
                g.add((obs_uri, SOSA.hasFeatureOfInterest, parcel_uri))
                g.add((obs_uri, SOSA.resultTime, Literal(obs_time, datatype=XSD.dateTime)))
                g.add((obs_uri, SOSA.hasResult, result_uri))
                g.add((obs_uri, ARDEN.sourceSystemId, Literal(f"YIELD_{parcel_id}_{obs_time}")))

                # Add result (QUDT QuantityValue pattern)
                g.add((result_uri, RDF.type, QUDT.QuantityValue))
                g.add((result_uri, QUDT.numericValue, Literal(yield_value, datatype=XSD.decimal)))
                g.add((result_uri, QUDT.unit, unit_iri))

                processed_rows += 1

            except Exception as e:
                validation_errors.append(f"Row {row_num}: Processing error: {str(e)}")
                continue

    # ETL Summary and Error Reporting
    print(f"\n=== ETL SUMMARY ===")
    print(f"Input: {csv_file_path}")
    print(f"Output: {output_file_path}")
    print(f"Processed rows: {processed_rows}")
    print(f"Generated triples: {len(g)}")
    print(f"Validation errors: {len(validation_errors)}")

    if validation_errors:
        print(f"\n=== VALIDATION ERRORS ===")
        for error in validation_errors[:10]:  # Show first 10 errors
            print(f"  ❌ {error}")
        if len(validation_errors) > 10:
            print(f"  ... and {len(validation_errors) - 10} more errors")
        print(f"\nRecommendation: Review data quality before production ingest")

    # Only write output if we have valid data
    if processed_rows > 0:
        with open(output_file_path, 'w') as outfile:
            outfile.write(g.serialize(format='turtle'))
        print(f"\n✅ RDF output written to: {output_file_path}")
    else:
        print(f"\n❌ No valid rows processed - no output file generated")

    return len(validation_errors) == 0

def main():
    if len(sys.argv) != 3:
        print("Usage: python csv_to_rdf_template.py <input.csv> <output.ttl>")
        print("\nExpected CSV format:")
        print("parcel_id,fips,obs_time,yield_bu_ac")
        print("42,19153,2023-10-01T00:00:00Z,185.2")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    # Run ETL with validation
    success = csv_to_rdf_yield_observations(input_file, output_file)

    # Exit with error code if validation failed
    if not success:
        print(f"\n⚠️  ETL completed with validation errors")
        sys.exit(2)  # Distinct exit code for validation failures
    else:
        print(f"\n🎉 ETL completed successfully - data ready for production ingest")

if __name__ == "__main__":
    main()