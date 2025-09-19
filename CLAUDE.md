# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an ontology development project focused on loan data modeling. The project structure is organized for semantic web technologies and ontology engineering.

## Directory Structure

- `ontology/` - Core ontology files (OWL, RDF, TTL)
- `mappings/` - Data mapping files for transforming source data to ontology instances
- `queries/` - SPARQL queries for data validation and analysis
- `shapes/` - SHACL shapes for data validation
- `scripts/` - Build and utility scripts
- `build/` - Generated ontology artifacts
- `release/` - Release versions of the ontology
- `externals/` - External ontologies and dependencies
- `loans_full.csv` - Sample loan data for testing and development

## Development Environment

The project uses a Python virtual environment (`.venv/`) with semantic web libraries. Key dependencies likely include:
- RDFLib for RDF processing
- OWL processing libraries
- SPARQL query engines

## Common Tasks

Since this is an ontology project, typical development tasks include:
- Building ontology files from source
- Validating ontology structure and consistency
- Running SPARQL queries for testing
- Generating documentation from ontology
- Creating data mappings from CSV to RDF

## Data Context

The project works with financial loan data including:
- Loan status, amounts, and balances
- Interest rates and payment schedules
- Loan types (Operating vs Term loans)
- Temporal data (start dates, maturity dates)

## Notes

- The `.cursor/rules/` directory contains outdated rules for a Next.js project and should be updated or removed for this ontology project
- Project is not yet initialized as a Git repository
- Most directories are currently empty and ready for ontology development