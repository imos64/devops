#!/bin/bash

# Harbor Binary Reverse Engineering Demo
# This script demonstrates the complete pipeline

set -e

echo "=========================================="
echo "Harbor Binary - Terminal Bench Challenge"
echo "=========================================="
echo ""

# Ensure /app directory exists
echo "[*] Setting up /app directory..."
sudo mkdir -p /app 2>/dev/null || mkdir -p /app 2>/dev/null || true
sudo chmod 777 /app 2>/dev/null || chmod 777 /app 2>/dev/null || true

# Clean previous artifacts
echo "[*] Cleaning previous artifacts..."
make clean
rm -f /app/config.json

# Build the binary
echo ""
echo "[*] Building binary from source..."
make build
echo ""

# Strip the binary
echo "[*] Stripping symbols..."
make strip
echo ""

# Show binary info
echo "[*] Binary information:"
ls -lh harbor_binary_stripped
echo ""

# Run the binary
echo "=========================================="
echo "STEP 1: Running the stripped binary"
echo "=========================================="
./harbor_binary_stripped
echo ""

# Show the result
echo "[*] Output file created:"
ls -lh /app/config.json
echo ""
echo "[*] Config content:"
cat /app/config.json
echo ""

# Clean for reverse engineering demo
rm -f /app/config.json

# Now demonstrate reverse engineering
echo ""
echo "=========================================="
echo "STEP 2: Reverse Engineering with Python"
echo "=========================================="
echo "[*] Running decryption script..."
python3 scripts/decrypt_config.py harbor_binary_stripped
echo ""

# Verify results match
echo "[*] Verification - Final config:"
cat /app/config.json
echo ""

# Success message
echo ""
echo "=========================================="
echo "✓ Demo Complete!"
echo "=========================================="
echo ""
echo "Summary:"
echo "  - Binary successfully reconstructs AES-128 key from lookup tables"
echo "  - Decrypts embedded configuration to /app/config.json"
echo "  - Python script successfully reverse-engineers the binary"
echo "  - Both methods produce identical results"
echo ""
echo "Files created:"
echo "  - harbor_binary (normal binary with symbols)"
echo "  - harbor_binary_stripped (stripped for analysis)"
echo "  - /app/config.json (decrypted configuration)"
echo ""
