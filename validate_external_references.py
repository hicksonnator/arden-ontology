#!/usr/bin/env python3
"""
Validate external ontologies are properly referenced in merged ontology
"""
import rdflib

def validate_external_references():
    print("Validating external ontology references in merged ontology...")

    # Load merged ontology
    g = rdflib.Graph()
    g.parse("release/arden-merged-v1.2.0.ttl", format="turtle")

    print(f"Total triples in merged ontology: {len(g)}")

    # SPARQL queries to check external ontology presence
    queries = {
        "SOSA entities": """
            SELECT (COUNT(?s) AS ?count) WHERE {
                ?s ?p ?o .
                FILTER(STRSTARTS(STR(?s), "http://www.w3.org/ns/sosa/"))
            }
        """,
        "QUDT entities": """
            SELECT (COUNT(?s) AS ?count) WHERE {
                ?s ?p ?o .
                FILTER(STRSTARTS(STR(?s), "http://qudt.org/"))
            }
        """,
        "GeoSPARQL entities": """
            SELECT (COUNT(?s) AS ?count) WHERE {
                ?s ?p ?o .
                FILTER(STRSTARTS(STR(?s), "http://www.opengis.net/ont/geosparql"))
            }
        """,
        "DCAT entities": """
            SELECT (COUNT(?s) AS ?count) WHERE {
                ?s ?p ?o .
                FILTER(STRSTARTS(STR(?s), "http://www.w3.org/ns/dcat"))
            }
        """,
        "PROV entities": """
            SELECT (COUNT(?s) AS ?count) WHERE {
                ?s ?p ?o .
                FILTER(STRSTARTS(STR(?s), "http://www.w3.org/ns/prov"))
            }
        """,
        "SKOS entities": """
            SELECT (COUNT(?s) AS ?count) WHERE {
                ?s ?p ?o .
                FILTER(STRSTARTS(STR(?s), "http://www.w3.org/2004/02/skos/core"))
            }
        """,
        "owl:imports statements": """
            PREFIX owl: <http://www.w3.org/2002/07/owl#>
            SELECT ?import WHERE {
                ?ontology owl:imports ?import .
            }
        """,
        "Arden entities using external classes": """
            PREFIX sosa: <http://www.w3.org/ns/sosa/>
            PREFIX qudt: <http://qudt.org/schema/qudt/>
            PREFIX geo: <http://www.opengis.net/ont/geosparql#>
            SELECT (COUNT(?s) AS ?count) WHERE {
                ?s ?p ?o .
                FILTER(STRSTARTS(STR(?s), "https://arden.ag/"))
                {
                    ?s a sosa:Observation
                } UNION {
                    ?s a qudt:QuantityKind
                } UNION {
                    ?s a geo:Geometry
                }
            }
        """
    }

    print("\n=== External Ontology Validation Results ===")

    for query_name, sparql in queries.items():
        try:
            results = g.query(sparql)
            if query_name == "owl:imports statements":
                imports = [str(row[0]) for row in results]
                print(f"\n{query_name}: {len(imports)} found")
                for imp in sorted(imports):
                    print(f"  - {imp}")
            else:
                count = next(results)[0]
                print(f"{query_name}: {count}")
        except Exception as e:
            print(f"Error executing query '{query_name}': {e}")

    # Check specific external classes are available
    print("\n=== Key External Classes Check ===")
    key_classes = [
        "http://www.w3.org/ns/sosa/Observation",
        "http://qudt.org/schema/qudt/QuantityKind",
        "http://www.opengis.net/ont/geosparql#Geometry",
        "http://www.w3.org/ns/dcat#Dataset",
        "http://www.w3.org/ns/prov#Entity",
        "http://www.w3.org/2004/02/skos/core#Concept"
    ]

    for class_uri in key_classes:
        count_query = f"""
            SELECT (COUNT(?s) AS ?count) WHERE {{
                {{ ?s a <{class_uri}> }} UNION
                {{ <{class_uri}> ?p ?o }}
            }}
        """
        try:
            results = g.query(count_query)
            count = next(results)[0]
            status = "✅" if count > 0 else "❌"
            print(f"{status} {class_uri}: {count} references")
        except Exception as e:
            print(f"❌ {class_uri}: Error - {e}")

if __name__ == "__main__":
    validate_external_references()