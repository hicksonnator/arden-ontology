#!/usr/bin/env python3
"""
Create merged Arden ontology with external dependencies
"""
import rdflib
import os
import sys

def create_merged_ontology():
    print("Creating merged Arden ontology with external dependencies...")

    # Create main graph
    g = rdflib.Graph()

    # Define namespace bindings
    g.bind('arden', rdflib.Namespace('https://arden.ag/ont/core#'))
    g.bind('sosa', rdflib.Namespace('http://www.w3.org/ns/sosa/'))
    g.bind('qudt', rdflib.Namespace('http://qudt.org/schema/qudt/'))
    g.bind('geo', rdflib.Namespace('http://www.opengis.net/ont/geosparql#'))
    g.bind('dcat', rdflib.Namespace('http://www.w3.org/ns/dcat#'))
    g.bind('prov', rdflib.Namespace('http://www.w3.org/ns/prov#'))
    g.bind('skos', rdflib.Namespace('http://www.w3.org/2004/02/skos/core#'))

    # External ontologies with formats
    external_files = [
        ('externals/sosa.ttl', 'turtle'),
        ('externals/qudt-schema.ttl', 'turtle'),
        ('externals/qudt-units.ttl', 'turtle'),
        ('externals/geosparql.rdf', 'xml'),
        ('externals/dcat.ttl', 'turtle'),
        ('externals/prov.ttl', 'turtle'),
        ('externals/skos.rdf', 'xml')
    ]

    # Arden ontology modules
    arden_files = [
        ('ontology/arden-core.ttl', 'turtle'),
        ('ontology/arden-ag.ttl', 'turtle'),
        ('ontology/arden-financial.ttl', 'turtle'),
        ('ontology/arden-geo.ttl', 'turtle'),
        ('ontology/arden-equipment.ttl', 'turtle'),
        ('ontology/arden-units.ttl', 'turtle'),
        ('ontology/arden-time.ttl', 'turtle'),
    ]

    # Load external ontologies
    for file_path, format_type in external_files:
        if os.path.exists(file_path):
            try:
                print(f"Loading external: {file_path}")
                g.parse(file_path, format=format_type)
            except Exception as e:
                print(f"Warning: Failed to load {file_path}: {e}")
        else:
            print(f"Warning: External file not found: {file_path}")

    # Load Arden ontology modules
    for file_path, format_type in arden_files:
        if os.path.exists(file_path):
            try:
                print(f"Loading Arden module: {file_path}")
                g.parse(file_path, format=format_type)
            except Exception as e:
                print(f"Warning: Failed to load {file_path}: {e}")
        else:
            print(f"Warning: Arden module not found: {file_path}")

    # Add owl:imports statements
    OWL = rdflib.Namespace("http://www.w3.org/2002/07/owl#")
    ARDEN_CORE = rdflib.URIRef("https://arden.ag/ont/core")

    # Add imports for external ontologies
    imports = [
        "http://www.w3.org/ns/sosa/",
        "http://qudt.org/2.1/schema/qudt",
        "http://www.opengis.net/ont/geosparql",
        "http://www.w3.org/ns/dcat",
        "http://www.w3.org/ns/prov",
        "http://www.w3.org/2004/02/skos/core"
    ]

    for import_iri in imports:
        g.add((ARDEN_CORE, OWL.imports, rdflib.URIRef(import_iri)))

    print(f"Total triples loaded: {len(g)}")

    # Serialize to Turtle format
    output_file = "release/arden-merged-v1.2.0.ttl"
    print(f"Writing merged ontology to: {output_file}")

    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(g.serialize(format='turtle'))
        print(f"Successfully created: {output_file}")
        return True
    except Exception as e:
        print(f"Error writing merged ontology: {e}")
        return False

if __name__ == "__main__":
    success = create_merged_ontology()
    sys.exit(0 if success else 1)