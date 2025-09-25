#!/usr/bin/env python3
"""
Runtime Release Checker for Arden Ontology
Checks if local ontology matches latest GitHub release
"""
import json
import hashlib
import requests
from pathlib import Path

def get_latest_release_info():
    """Fetch latest release info from GitHub"""
    url = "https://raw.githubusercontent.com/hicksonnator/arden-ontology/master/LATEST_RELEASE.json"
    response = requests.get(url)
    response.raise_for_status()
    return response.json()

def calculate_sha256(file_path):
    """Calculate SHA256 hash of local file"""
    sha256_hash = hashlib.sha256()
    with open(file_path, "rb") as f:
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()

def check_ontology_version(local_ontology_path=None):
    """
    Check if local ontology matches latest release
    Returns: (is_current, local_version, latest_version, action_needed)
    """
    try:
        latest = get_latest_release_info()

        if not local_ontology_path or not Path(local_ontology_path).exists():
            return False, None, latest["version"], "DOWNLOAD_REQUIRED"

        # Check file integrity
        local_hash = calculate_sha256(local_ontology_path)
        if local_hash != latest["sha256"]:
            return False, "unknown", latest["version"], "UPDATE_REQUIRED"

        return True, latest["version"], latest["version"], "UP_TO_DATE"

    except Exception as e:
        return False, "unknown", "unknown", f"ERROR: {e}"

def main():
    """Example usage for harvester startup check"""
    print("🔍 Checking Arden Ontology version...")

    # Example: Check against local file
    local_file = "arden-ontology-production-v1.2.2-20250925-141918.tar.gz"

    is_current, local_ver, latest_ver, action = check_ontology_version(local_file)

    print(f"Local version: {local_ver}")
    print(f"Latest version: {latest_ver}")
    print(f"Status: {action}")

    if action == "DOWNLOAD_REQUIRED":
        print("⚠️  No local ontology found - download required")
        return False
    elif action == "UPDATE_REQUIRED":
        print("⚠️  Local ontology outdated - update required")
        return False
    elif action == "UP_TO_DATE":
        print("✅ Local ontology is current")
        return True
    else:
        print(f"❌ Version check failed: {action}")
        return False

if __name__ == "__main__":
    main()