# Harbor Binary Setup and Reverse Engineering Challenge

## Overview

This repository contains a complete implementation of the Harbor challenge for the Terminal Bench evaluation framework. It demonstrates a realistic scenario where an AES-128 encryption key must be reconstructed from scattered lookup tables embedded in a stripped ELF binary.

## Quick Start

### Build Everything
```bash
make all
```

### Run the Binary
```bash
./harbor_binary_stripped
```

### Run the Decryption Script
```bash
python3 scripts/decrypt_config.py harbor_binary_stripped
```

### Verify Output
```bash
cat /app/config.json
```

Expected output:
```json
{
  "service": "harbor",
  "version": "1.0",
  "secret": "terminal_bench_2024"
}
```

## What This Demonstrates

### 1. Key Reconstruction from Scattered Data
- **Challenge**: The AES-128 key is not stored as a single contiguous block
- **Technique**: 16 key bytes are reconstructed by XORing values from 4 different lookup tables
- **Obfuscation**: Each key byte requires combining data from specific positions across multiple tables

### 2. Binary Reverse Engineering
- **Stripped Binary**: No symbols or debugging information
- **Static Analysis**: Pattern matching to find data structures
- **Dynamic Analysis**: Understanding runtime behavior from static inspection

### 3. Custom Cryptography Analysis
- **Algorithm**: Custom XOR-based encryption with AES S-box mixing
- **Key Derivation**: Non-standard key reconstruction logic
- **Decryption**: Reverse engineering without documentation

## Repository Structure

```
harbor/
├── src/
│   └── harbor_binary.c              # Source implementing key reconstruction
│
├── scripts/
│   ├── decrypt_config.py            # Main RE script - extracts & decrypts
│   ├── generate_encrypted_config.py # Helper to create encrypted blobs
│   └── find_data.py                 # Binary analysis helper
│
├── Makefile                          # Build system
├── README.md                         # Main documentation
├── ANALYSIS.md                       # Detailed technical analysis
├── SETUP.md                          # This file
└── .gitignore                        # Git ignore rules
```

## Components

### C Binary (`harbor_binary.c`)
- Implements scattered lookup tables (4 × 32 bytes)
- Contains key reconstruction algorithm
- Embeds encrypted JSON configuration (72 bytes)
- Decrypts and writes to `/app/config.json`

### Python Decryption Script (`decrypt_config.py`)
- Extracts lookup tables from binary using pattern matching
- Locates encrypted data blob
- Reconstructs the AES-128 key
- Implements the decryption algorithm
- Writes JSON to `/app/config.json`

### Build System (`Makefile`)
- **make all**: Compile and strip binary
- **make build**: Compile only
- **make strip**: Strip symbols
- **make test**: Run full test suite
- **make clean**: Remove artifacts

## Key Technical Details

### Lookup Tables

Four 32-byte tables scattered in `.rodata`:

| Table   | Start Pattern            | Purpose            |
|---------|-------------------------|--------------------|
| table_a | `45 2b 7e 15 16 28`     | Key bytes 0,4,8,12 |
| table_b | `91 3d 47 b8 f2 6c`     | Key bytes 1,5,9,13 |
| table_c | `56 aa dc 71 2f 98`     | Key bytes 2,6,10,14|
| table_d | `88 1f c9 5b 6e d5`     | Key bytes 3,7,11,15|

### Encrypted Data

- **Location**: `.rodata` section
- **Size**: 72 bytes
- **Signature**: `58 ff ba 35 49 41`
- **Content**: JSON configuration

### AES-128 Key

- **Value**: `40186209a71116cb864904860612d29f`
- **Construction**: XOR of values from multiple lookup tables
- **Usage**: Keystream for decryption (repeating 16-byte pattern)

### Decryption Algorithm

```
plaintext[i] = ciphertext[i] ^ key[i mod 16] ^ SBOX[(i * 7) mod 256]
```

Where:
- `key`: Reconstructed 16-byte AES-128 key
- `SBOX`: Standard AES S-box (256 bytes)
- `i`: Position in ciphertext (0-71)

## Testing

### Automated Test
```bash
make test
```

This runs:
1. Compilation with optimizations
2. Symbol stripping
3. Binary execution
4. Python script verification
5. Output comparison

### Manual Testing

#### Test Binary:
```bash
./harbor_binary_stripped
cat /app/config.json
```

#### Test Script:
```bash
python3 scripts/decrypt_config.py harbor_binary_stripped
cat /app/config.json
```

#### Test Standalone:
```bash
python3 scripts/decrypt_config.py
cat /app/config.json
```

All three methods should produce identical output.

## Reverse Engineering Workflow

### Step 1: Reconnaissance
```bash
# Check binary type
ls -lh harbor_binary_stripped

# Look for strings (minimal in stripped binary)
strings harbor_binary_stripped
```

### Step 2: Extract Data Structures
```python
# Find lookup tables
python3 scripts/find_data.py
```

### Step 3: Analyze Key Reconstruction
- Study the pattern of table access
- Identify XOR operations
- Map indices to key bytes

### Step 4: Locate Encrypted Data
- Search for data blob signatures
- Determine encryption boundaries
- Extract ciphertext

### Step 5: Reverse Engineer Crypto
- Identify S-box usage
- Understand keystream generation
- Implement decryption

### Step 6: Decrypt & Verify
```bash
python3 scripts/decrypt_config.py harbor_binary_stripped
```

## Educational Value

This challenge teaches:

1. **Binary Analysis**: Reading stripped ELF files
2. **Pattern Matching**: Finding data structures without symbols
3. **Algorithm RE**: Understanding code from behavior
4. **Crypto Analysis**: Breaking custom encryption schemes
5. **Scripting**: Automating reverse engineering tasks

## Limitations & Security Notes

⚠️ **For Educational Use Only**

This is a simplified demonstration. Real-world applications should:

- Use standard crypto libraries (OpenSSL, libsodium)
- Never embed keys in binaries
- Implement proper key management (KMS/HSM)
- Use authenticated encryption (AES-GCM, ChaCha20-Poly1305)
- Add anti-tampering and obfuscation
- Follow security best practices

## Troubleshooting

### Binary Won't Run
```bash
# Ensure /app directory exists and is writable
sudo mkdir -p /app
sudo chmod 777 /app
```

### Script Can't Find Data
```bash
# Verify binary was built correctly
make clean
make all

# Check binary size (should be ~15KB)
ls -lh harbor_binary_stripped
```

### Wrong Output
```bash
# Rebuild everything
make clean
make test
```

## Performance

- **Compilation**: <1 second
- **Binary Execution**: <0.1 seconds
- **Script Analysis**: <0.5 seconds
- **Total Pipeline**: <2 seconds

## Dependencies

### Build Requirements
- GCC (any modern version)
- Make
- strip utility

### Runtime Requirements
- Python 3.6+
- Standard library only (no external packages)

### System Requirements
- Linux (x86_64)
- Writable `/app` directory
- ~100MB disk space

## Contributing

This is a reference implementation for the Terminal Bench framework. Enhancements welcome:

- Additional obfuscation techniques
- More complex key derivation
- Alternative crypto algorithms
- Anti-debugging measures
- Performance optimizations

## References

- Terminal Bench Evaluation Framework
- AES Specification (FIPS 197)
- ELF Format Specification
- Reverse Engineering Best Practices

## Contact

For questions about the Terminal Bench framework or this challenge, please refer to the main framework documentation.
