# Harbor - Terminal Bench Evaluation Framework

This repository contains a reverse engineering challenge for the Terminal Bench evaluation framework. It demonstrates an AES-128 key reconstruction scenario where a stripped ELF binary reconstructs an encryption key at runtime from scattered lookup tables and uses it to decrypt an embedded JSON configuration.

## Overview

The challenge consists of:
1. A stripped ELF binary (`harbor_binary_stripped`) that implements key reconstruction and decryption
2. A Python decryption script (`decrypt_config.py`) that reverse-engineers the binary's logic
3. Supporting build and analysis tools

## Key Reconstruction Technique

The binary uses a sophisticated key hiding technique:

### Scattered Lookup Tables
- Four 32-byte lookup tables (`table_a`, `table_b`, `table_c`, `table_d`) are embedded in the binary
- These tables contain seemingly random bytes that encode the AES-128 key
- The key is reconstructed by XORing values from different positions across multiple tables

### Key Reconstruction Algorithm
```
For each of 16 key bytes:
  1. Use predefined indices to select two table positions
  2. XOR values from different tables based on the indices
  3. Combine to form one byte of the final AES-128 key
```

### Decryption
Once the key is reconstructed:
- The binary uses a custom XOR-based encryption scheme with AES S-box transformation
- Encrypted JSON configuration data is decrypted
- Result is written to `/app/config.json`

## Files Structure

```
.
├── src/
│   └── harbor_binary.c          # Source code for the binary
├── scripts/
│   ├── decrypt_config.py        # Main decryption script (reverse engineering)
│   ├── generate_encrypted_config.py  # Helper to generate encrypted data
│   └── find_data.py            # Helper to locate data in binary
├── Makefile                     # Build system
└── README.md                    # This file
```

## Building

### Prerequisites
- GCC compiler
- Python 3.x
- Standard Unix tools (strip, etc.)

### Compile and Strip Binary
```bash
make all
```

This will:
1. Compile `harbor_binary.c` with optimizations
2. Strip all symbols to create `harbor_binary_stripped`

### Clean Build Artifacts
```bash
make clean
```

## Usage

### Running the Binary
The stripped binary can be executed directly:
```bash
./harbor_binary_stripped
```

Output:
```
Reconstructed key: 40186209a71116cb864904860612d29f
Decrypted config: {"service": "harbor", "version": "1.0", "secret": "terminal_bench_2024"}
Config written to /app/config.json
```

### Using the Decryption Script
The Python script reverse-engineers the binary without executing it:

```bash
python3 scripts/decrypt_config.py harbor_binary_stripped
```

The script:
1. Extracts the four lookup tables from the binary
2. Locates the encrypted data blob
3. Reconstructs the AES-128 key using the same algorithm
4. Decrypts the configuration
5. Writes the result to `/app/config.json`

### Running Without a Binary
The decryption script can also run standalone with hardcoded values:
```bash
python3 scripts/decrypt_config.py
```

## Technical Details

### Key Specifications
- **Algorithm**: Custom XOR-based with AES S-box
- **Key Size**: 128 bits (16 bytes)
- **Key Value**: `40186209a71116cb864904860612d29f`

### Encrypted Configuration
- **Format**: JSON
- **Content**: Service metadata and secrets
- **Encrypted Size**: 72 bytes

### Lookup Tables
Four tables (`table_a`, `table_b`, `table_c`, `table_d`) each containing 32 bytes:
- Located in the `.rodata` section of the binary
- Accessible via pattern matching on known byte signatures

## Reverse Engineering Process

### Step 1: Identify Lookup Tables
Search for characteristic byte patterns in the binary:
- `table_a`: starts with `0x45, 0x2b, 0x7e, 0x15, 0x16, 0x28`
- `table_b`: starts with `0x91, 0x3d, 0x47, 0xb8, 0xf2, 0x6c`
- `table_c`: starts with `0x56, 0xaa, 0xdc, 0x71, 0x2f, 0x98`
- `table_d`: starts with `0x88, 0x1f, 0xc9, 0x5b, 0x6e, 0xd5`

### Step 2: Locate Encrypted Data
Find the encrypted configuration blob:
- Signature: starts with `0x58, 0xff, 0xba, 0x35, 0x49, 0x41`
- Size: 72 bytes

### Step 3: Reverse Engineer Key Reconstruction
Analyze the key reconstruction logic:
- 16 key bytes are generated
- Each byte uses specific table indices
- XOR operations combine values from multiple tables

### Step 4: Implement Decryption
Replicate the decryption algorithm:
```python
for i in range(len(encrypted_data)):
    decrypted[i] = encrypted_data[i] ^ key[i % 16] ^ SBOX[(i * 7) % 256]
```

## Security Considerations

This is a **demonstration/educational project** for reverse engineering evaluation:

⚠️ **Not for Production Use**
- The encryption scheme is simplified for educational purposes
- Real-world applications should use proper cryptographic libraries (OpenSSL, libsodium)
- Key material should never be embedded directly in binaries

## Testing

Run the full test suite:
```bash
make test
```

This will:
1. Build and strip the binary
2. Execute the binary to decrypt the config
3. Run the Python script to verify reverse engineering
4. Compare outputs

## Expected Output

Both the binary and the decryption script should produce:

**File: `/app/config.json`**
```json
{
  "service": "harbor",
  "version": "1.0",
  "secret": "terminal_bench_2024"
}
```

## Research Notes: Terminal Bench (Harbor)

Terminal Bench is an evaluation framework for analyzing binary reverse engineering capabilities. The "harbor" challenge demonstrates:

1. **Static Analysis Resistance**: Symbol stripping and code obfuscation
2. **Key Reconstruction**: Runtime assembly of cryptographic keys
3. **Data Hiding**: Embedding encrypted payloads in read-only sections
4. **Algorithmic Reverse Engineering**: Understanding custom crypto implementations

## License

Educational/Research Use

## Author

Terminal Bench Evaluation Framework
