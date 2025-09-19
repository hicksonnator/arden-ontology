#!/usr/bin/env bash
set -euo pipefail
mkdir -p externals

echo "Fetching core semantic web foundations..."

# Pin minimal kernels; the rest will be sliced via ROBOT MIREOT
curl -L -o externals/sosa.ttl        https://www.w3.org/ns/sosa/sosa.ttl
curl -L -o externals/geosparql.ttl   https://schemas.opengis.net/geosparql/1.1/geosparql.ttl
curl -L -o externals/qudt.ttl        https://qudt.org/2.1/schema/qudt.ttl
curl -L -o externals/unit.ttl        https://qudt.org/2.1/vocab/unit
curl -L -o externals/qb.ttl          https://www.w3.org/TR/vocab-data-cube/ttl/data-cube.ttl

echo "Fetching new foundations for enterprise modules..."

# SKOS core (for AGROVOC alignment)
curl -L -o externals/skos.rdf        https://www.w3.org/2004/02/skos/core.rdf

# PROV-O (provenance for permits/certs)
curl -L -o externals/prov-o.owl      https://www.w3.org/ns/prov-o-20130430.owl

# DCAT (data catalog vocabulary)
curl -L -o externals/dcat.ttl        https://www.w3.org/ns/dcat.ttl

# VoID (describing linked datasets)
curl -L -o externals/void.ttl        http://vocab.deri.ie/void.ttl

# Time ontology
curl -L -o externals/time.ttl        https://www.w3.org/2006/time

echo "Fetch complete. Add others you plan to slice (AGRO/ENVO/FIBO/etc.) as needed, pinned by version."