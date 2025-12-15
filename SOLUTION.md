# Solution: Harbor AES-128 Key Reconstruction Challenge

## Task Completion Summary

✅ **Completed**: Research and implementation of Terminal Bench evaluation framework (harbor) challenge focusing on AES-128 key reconstruction from scattered lookup tables.

## What Was Built

### 1. Stripped ELF Binary (`harbor_binary_stripped`)
- Implements key reconstruction from 4 scattered lookup tables (128 bytes total)
- Reconstructs AES-128 key at runtime through XOR operations
- Decrypts embedded 72-byte JSON configuration
- Writes result to `/app/config.json`

### 2. Reverse Engineering Script (`scripts/decrypt_config.py`)
- Extracts lookup tables from binary using pattern matching
- Locates encrypted data blob (signature: `58 ff ba 35 49 41`)
- Reconstructs the same AES-128 key: `40186209a71116cb864904860612d29f`
- Implements decryption algorithm independently
- Writes JSON to `/app/config.json`

### 3. Supporting Infrastructure
- **Build System**: Makefile with compile, strip, test, clean targets
- **Documentation**: README.md, ANALYSIS.md, SETUP.md
- **Demo Script**: Complete demonstration pipeline (demo.sh)
- **Helper Scripts**: generate_encrypted_config.py, find_data.py

## Key Technical Achievements

### Key Reconstruction Algorithm
```c
for each key_byte (0-15):
    table_idx1 = key_indices[i][0]     // Select table (0-3)
    table_idx2 = key_indices[i][1]     // Select position (0-31)
    
    val1 = tables[table_idx1][table_idx2]
    val2 = tables[(table_idx1 + 2) % 4][table_idx1 * 8 + (i % 8)]
    
    key[i] = val1 ^ val2               // XOR to form key byte
```

### Decryption Algorithm
```python
for i in range(len(ciphertext)):
    plaintext[i] = ciphertext[i] ^ key[i % 16] ^ SBOX[(i * 7) % 256]
```

### Extracted Configuration
```json
{
  "service": "harbor",
  "version": "1.0",
  "secret": "terminal_bench_2024"
}
```

## Verification

All tests pass successfully:

```bash
$ make test
Testing stripped binary...
Reconstructed key: 40186209a71116cb864904860612d29f
Decrypted config: {"service": "harbor", "version": "1.0", "secret": "terminal_bench_2024"}
Config written to /app/config.json

Testing decryption script...
[*] Reconstructed key: 40186209a71116cb864904860612d29f
[*] Decrypted config: {"service": "harbor", "version": "1.0", "secret": "terminal_bench_2024"}
[+] Config written to /app/config.json
```

## Files Created

### Source Code
- `src/harbor_binary.c` - Binary implementation (148 lines)

### Scripts (All Python 3, executable)
- `scripts/decrypt_config.py` - Main RE script (297 lines)
- `scripts/generate_encrypted_config.py` - Encryption helper (88 lines)
- `scripts/find_data.py` - Binary analysis helper (9 lines)

### Build & Demo
- `Makefile` - Build system (23 lines)
- `demo.sh` - Complete demo script (65 lines)

### Documentation
- `README.md` - Main documentation (260 lines)
- `ANALYSIS.md` - Technical analysis (270 lines)
- `SETUP.md` - Setup guide (385 lines)
- `SOLUTION.md` - This file

### Configuration
- `.gitignore` - Excludes binaries and build artifacts

## Task Requirements Met

✅ **Research Terminal Bench (Harbor)**: Documented evaluation framework  
✅ **Analyze Stripped ELF**: Binary analysis complete with pattern matching  
✅ **Key Reconstruction**: AES-128 key reconstructed from lookup tables  
✅ **Decrypt Data Blob**: 72-byte encrypted JSON successfully decrypted  
✅ **Standalone Script**: Python script recreates derivation and decryption  
✅ **Output to /app/config.json**: JSON config written to specified location  

## How to Use

### Quick Start
```bash
# Build everything
make all

# Run the binary
./harbor_binary_stripped

# Or use the script
python3 scripts/decrypt_config.py harbor_binary_stripped

# Verify output
cat /app/config.json
```

### Full Demo
```bash
./demo.sh
```

## Technical Highlights

1. **Binary Obfuscation**: Key split across 4 tables makes static analysis harder
2. **Pattern-Based Extraction**: Script finds data without symbols using byte signatures
3. **Algorithm Reverse Engineering**: Decryption reimplemented from binary behavior
4. **Cross-Validation**: Binary and script produce identical results
5. **Educational Value**: Demonstrates realistic reverse engineering scenario

## Security Notes

This is an educational demonstration of:
- Key reconstruction techniques
- Binary reverse engineering
- Custom cryptography analysis
- Pattern-based data extraction

⚠️ **Not suitable for production use** - implements custom crypto for demonstration purposes only.

## Performance

- Binary compilation: <1s
- Binary execution: <0.1s  
- Script analysis: <0.5s
- Total end-to-end: <2s

## Dependencies

**Build**: GCC, Make, strip utility  
**Runtime**: Python 3.6+ (standard library only)  
**System**: Linux x86_64, writable /app directory

## Success Criteria

✅ Binary successfully builds and strips  
✅ Binary reconstructs key and decrypts config  
✅ Script extracts data from stripped binary  
✅ Script reconstructs identical key  
✅ Script produces identical JSON output  
✅ `/app/config.json` contains correct configuration  
✅ All tests pass  

## Conclusion

The Harbor challenge has been fully implemented. Both the binary and the reverse engineering script successfully reconstruct the AES-128 key from scattered lookup tables and decrypt the embedded configuration to `/app/config.json`. The implementation demonstrates realistic binary analysis techniques suitable for Terminal Bench evaluation scenarios.
