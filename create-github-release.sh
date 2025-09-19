#!/bin/bash
# GitHub Release Creation Script for Arden Ontology v1.2.0

set -euo pipefail

echo "🚀 Creating GitHub Release for Arden Ontology v1.2.0"
echo "=================================================="

# Check if we're in the right directory
if [ ! -f "arden-ontology-production-v1.2.0-20250919-124206.tar.gz" ]; then
    echo "❌ Release artifact not found. Make sure you're in the arden-ontology directory."
    exit 1
fi

# Use local GitHub CLI
GH="./bin/gh.exe"

# Check if GitHub CLI is available
if [ ! -f "$GH" ]; then
    echo "❌ GitHub CLI not found at $GH"
    echo "Please run: curl -L https://github.com/cli/cli/releases/download/v2.79.0/gh_2.79.0_windows_amd64.zip -o gh.zip && unzip gh.zip"
    exit 1
fi

echo "✅ GitHub CLI found: $($GH --version)"

# Check authentication
if ! $GH auth status >/dev/null 2>&1; then
    echo "⚠️  You need to authenticate with GitHub first."
    echo "Run: $GH auth login"
    echo "Then run this script again."
    exit 1
fi

echo "✅ GitHub authentication verified"

# Create the release
echo "📦 Creating GitHub release v1.2.0..."

$GH release create v1.2.0 \
  --title "Arden Ontology v1.2.0 - Production Ready" \
  --notes "# 🌾 Arden Ontology v1.2.0 - Production Ready

Complete enterprise-grade agricultural infrastructure ontology with production deployment capabilities.

## ✨ Key Features
- **Modular Architecture**: Core, Agriculture, Financial, Geospatial, Equipment domains
- **Real Data Integration**: USDA NASS, RMA, Census datasets with DCAT metadata
- **Validation Pipeline**: Multi-tier SHACL constraints (L1-L3) + domain-specific rules
- **Production Infrastructure**: Health monitoring, ETL guardrails, deployment runbooks
- **Enterprise Governance**: Change control, access management, rollback procedures

## 📦 Release Contents
- **File**: \`arden-ontology-production-v1.2.0-20250919-124206.tar.gz\`
- **SHA256**: \`57b8c72122dc150b69c5de80f909a906673df711035729b54f248f08b131f10a\`
- **Size**: 38KB

## 🚀 Quick Start
\`\`\`bash
# Download and verify
curl -L -o ontology.tar.gz \\
  \"https://github.com/hicksonnator/arden-ontology/releases/download/v1.2.0/arden-ontology-production-v1.2.0-20250919-124206.tar.gz\"

# Verify integrity
echo \"57b8c72122dc150b69c5de80f909a906673df711035729b54f248f08b131f10a ontology.tar.gz\" | sha256sum -c

# Extract and deploy
tar -xzf ontology.tar.gz
cd release && bash scripts/validate_samples.sh
\`\`\`

## 🔧 Environment Variables for arden-harvest
\`\`\`bash
ARDEN_ONTOLOGY_VERSION=v1.2.0
ARDEN_ONTOLOGY_SHA256=57b8c72122dc150b69c5de80f909a906673df711035729b54f248f08b131f10a
ARDEN_ONTOLOGY_URL=https://github.com/hicksonnator/arden-ontology/releases/download/v1.2.0/arden-ontology-production-v1.2.0-20250919-124206.tar.gz
ARDEN_ONTOLOGY_PATH=/ontology
\`\`\`

## 📋 Production Deployment
1. Follow [PRODUCTION_RUNBOOK.md](PRODUCTION_RUNBOOK.md) for complete deployment guide
2. Use [Named Graphs Strategy](docs/named-graphs-access-model.md) for enterprise setup
3. Implement [Governance Framework](docs/governance-change-control.md) for change control
4. Monitor with [Health Dashboard](queries/probe-health-dashboard.rq)

## 🎯 What's Included
- **Ontology Modules**: 12 domain-specific TTL files
- **Real Agricultural Data**: NASS yields, RMA policies, Census demographics, FIPS counties
- **Validation Shapes**: SHACL constraints for data quality assurance
- **ETL Pipeline**: CSV-to-RDF conversion with validation guardrails
- **Deployment Scripts**: Build, validate, package, and deploy automation
- **Documentation**: Complete runbooks, governance, and technical guides

**Status**: ✅ PRODUCTION-PROVEN - Ready for enterprise agricultural data infrastructure!" \
  arden-ontology-production-v1.2.0-20250919-124206.tar.gz

if [ $? -eq 0 ]; then
    echo "✅ Release created successfully!"
    echo ""
    echo "🔗 Release URL: https://github.com/hicksonnator/arden-ontology/releases/tag/v1.2.0"
    echo "📦 Download URL: https://github.com/hicksonnator/arden-ontology/releases/download/v1.2.0/arden-ontology-production-v1.2.0-20250919-124206.tar.gz"
    echo ""
    echo "🎯 Environment Variables for arden-harvest:"
    echo "ARDEN_ONTOLOGY_VERSION=v1.2.0"
    echo "ARDEN_ONTOLOGY_SHA256=57b8c72122dc150b69c5de80f909a906673df711035729b54f248f08b131f10a"
    echo "ARDEN_ONTOLOGY_URL=https://github.com/hicksonnator/arden-ontology/releases/download/v1.2.0/arden-ontology-production-v1.2.0-20250919-124206.tar.gz"
    echo "ARDEN_ONTOLOGY_PATH=/ontology"
else
    echo "❌ Release creation failed"
    exit 1
fi