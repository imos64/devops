# Implementation Details: Harbor AES-128 Key Reconstruction

## Overview

This document provides implementation-specific details for developers working with or extending the Harbor challenge.

## Architecture

### Data Flow

```
┌─────────────────────────────────────────────────────────┐
│                    BINARY RUNTIME                       │
├─────────────────────────────────────────────────────────┤
│  1. Read lookup tables from .rodata                     │
│     • table_a[32], table_b[32], table_c[32], table_d[32]│
│                                                          │
│  2. Reconstruct AES-128 key (16 bytes)                  │
│     • For each key byte: XOR values from 2 tables       │
│     • Result: 40186209a71116cb864904860612d29f           │
│                                                          │
│  3. Read encrypted data from .rodata (72 bytes)         │
│                                                          │
│  4. Decrypt using custom algorithm                      │
│     • plaintext[i] = cipher[i] ^ key[i%16] ^ sbox[...]  │
│                                                          │
│  5. Write JSON to /app/config.json                      │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                REVERSE ENGINEERING SCRIPT               │
├─────────────────────────────────────────────────────────┤
│  1. Read binary file                                    │
│                                                          │
│  2. Pattern match to find lookup tables                 │
│     • Search for known byte signatures                  │
│     • Extract 4 × 32-byte tables                        │
│                                                          │
│  3. Locate encrypted data                               │
│     • Find signature: 58 ff ba 35 49 41                 │
│     • Extract 72 bytes                                  │
│                                                          │
│  4. Reconstruct key (same algorithm as binary)          │
│                                                          │
│  5. Decrypt (same algorithm as binary)                  │
│                                                          │
│  6. Parse JSON and write to /app/config.json            │
└─────────────────────────────────────────────────────────┘
```

## Key Data Structures

### Lookup Tables (4 × 32 bytes = 128 bytes total)

```c
static const uint8_t table_a[32] = { /* values */ };
static const uint8_t table_b[32] = { /* values */ };
static const uint8_t table_c[32] = { /* values */ };
static const uint8_t table_d[32] = { /* values */ };
```

**Memory Layout in Binary:**
- Located in `.rodata` section (read-only data)
- Contiguous or near-contiguous placement
- No alignment padding (byte arrays)

### Key Indices (16 × 2 bytes = 32 bytes)

```c
static const uint8_t key_indices[16][2] = {
    {0, 4},   {1, 17},  {2, 10},  {3, 20},
    {0, 12},  {1, 25},  {2, 9},   {3, 22},
    {0, 30},  {1, 3},   {2, 21},  {3, 6},
    {0, 24},  {1, 19},  {2, 27},  {3, 31}
};
```

**Interpretation:**
- `key_indices[i][0]`: Which table (0=a, 1=b, 2=c, 3=d)
- `key_indices[i][1]`: Position in that table (0-31)

### AES S-box (256 bytes)

Standard AES S-box used for additional mixing.

### Encrypted Data (72 bytes)

JSON configuration encrypted with custom algorithm.

## Algorithms

### Key Reconstruction

**Function:** `reconstruct_key(uint8_t *key)`

**Algorithm:**
```
Input: 4 lookup tables (table_a, table_b, table_c, table_d)
Output: 16-byte AES-128 key

For i from 0 to 15:
    table_idx1 = key_indices[i][0]
    table_idx2 = key_indices[i][1]
    
    tables = [table_a, table_b, table_c, table_d]
    
    val1 = tables[table_idx1][table_idx2]
    val2 = tables[(table_idx1 + 2) mod 4][table_idx1 × 8 + (i mod 8)]
    
    key[i] = val1 XOR val2
```

**Example (Key Byte 0):**
```
i = 0
table_idx1 = key_indices[0][0] = 0
table_idx2 = key_indices[0][1] = 4

val1 = table_a[4] = 0x16
val2 = table_c[0 × 8 + 0] = table_c[0] = 0x56

key[0] = 0x16 XOR 0x56 = 0x40
```

### Decryption

**Function:** `decrypt_data(encrypted, decrypted, len, key)`

**Algorithm:**
```
Input: encrypted[len], key[16], len
Output: decrypted[len]

For i from 0 to len-1:
    decrypted[i] = encrypted[i] XOR key[i mod 16] XOR sbox[(i × 7) mod 256]
```

**Properties:**
- Symmetric (same operation for encrypt/decrypt)
- Key repeats every 16 bytes
- S-box mixing changes per position

## Binary Analysis Techniques

### 1. Pattern Matching

**Signatures for lookup tables:**
```python
table_a_sig = bytes([0x45, 0x2b, 0x7e, 0x15, 0x16, 0x28])
table_b_sig = bytes([0x91, 0x3d, 0x47, 0xb8, 0xf2, 0x6c])
table_c_sig = bytes([0x56, 0xaa, 0xdc, 0x71, 0x2f, 0x98])
table_d_sig = bytes([0x88, 0x1f, 0xc9, 0x5b, 0x6e, 0xd5])
```

**Search:**
```python
idx = binary_data.find(signature)
table = binary_data[idx:idx+32]
```

### 2. Encrypted Data Location

**Signature:**
```python
encrypted_sig = bytes([0x58, 0xff, 0xba, 0x35, 0x49, 0x41])
```

**Extraction:**
```python
idx = binary_data.find(encrypted_sig)
encrypted = binary_data[idx:idx+72]
```

## Build Process

### Compilation

```bash
gcc -Wall -O2 src/harbor_binary.c -o harbor_binary
```

**Flags:**
- `-Wall`: All warnings
- `-O2`: Optimization level 2 (balance speed/size)

### Symbol Stripping

```bash
strip -s harbor_binary -o harbor_binary_stripped
```

**Effect:**
- Removes symbol table
- Removes debug information
- Reduces binary size (~17KB → ~15KB)
- Makes reverse engineering harder

### Size Comparison

| Binary                   | Size   | Symbols |
|--------------------------|--------|---------|
| harbor_binary            | ~17KB  | Yes     |
| harbor_binary_stripped   | ~15KB  | No      |

## Python Script Implementation

### Key Functions

**1. `find_pattern_in_binary(data, pattern)`**
- Locates byte patterns in binary
- Returns offset or -1

**2. `extract_lookup_tables(binary_data)`**
- Finds all 4 tables using signatures
- Falls back to hardcoded values if not found
- Returns 4 × 32-byte arrays

**3. `extract_encrypted_data(binary_data)`**
- Locates encrypted blob
- Extracts 72 bytes
- Falls back to hardcoded values

**4. `reconstruct_key(table_a, table_b, table_c, table_d)`**
- Implements same logic as binary
- Returns 16-byte key

**5. `decrypt_data(encrypted_data, key)`**
- Implements decryption algorithm
- Returns plaintext bytes

**6. `main()`**
- Orchestrates full pipeline
- Writes `/app/config.json`

### Error Handling

- **Binary not found**: Use hardcoded values
- **Pattern not found**: Use hardcoded values
- **Invalid UTF-8**: Print hex dump
- **Invalid JSON**: Write as plain text
- **Directory missing**: Create `/app` directory

## Testing Strategy

### Unit Tests (Implicit)

1. **Key reconstruction**: Verify key matches expected value
2. **Decryption**: Verify plaintext is valid JSON
3. **JSON parsing**: Verify fields present and correct

### Integration Tests

1. **Binary execution**: Run `./harbor_binary_stripped`
2. **Script execution**: Run `python3 scripts/decrypt_config.py`
3. **Output comparison**: Both produce identical `/app/config.json`

### Test Command

```bash
make test
```

**Test Flow:**
1. Clean previous artifacts
2. Build binary
3. Strip symbols
4. Execute binary → verify output
5. Execute script → verify output
6. Compare results

## Extension Points

### Adding More Tables

1. Define new table in C source
2. Add signature to Python script
3. Update key reconstruction logic
4. Increase key size if needed

### Changing Encryption

1. Modify `decrypt_data()` in C
2. Update Python equivalent
3. Regenerate encrypted data
4. Update tests

### Additional Obfuscation

1. Add code flow obfuscation
2. Implement anti-debugging checks
3. Add fake tables as decoys
4. Use packing/compression

## Performance Characteristics

### Binary
- **Compilation**: O(n) where n = source lines
- **Key reconstruction**: O(1) - fixed 16 iterations
- **Decryption**: O(m) where m = encrypted data length
- **Total runtime**: <100ms

### Python Script
- **Binary read**: O(b) where b = binary size
- **Pattern search**: O(b) worst case
- **Key reconstruction**: O(1)
- **Decryption**: O(m)
- **Total runtime**: <500ms

## Memory Usage

### Binary
- **Lookup tables**: 128 bytes
- **Key indices**: 32 bytes
- **S-box**: 256 bytes
- **Encrypted data**: 72 bytes
- **Stack**: ~1KB for buffers
- **Total**: ~2KB data, ~5KB code

### Python Script
- **Binary buffer**: ~15KB
- **Tables**: 128 bytes
- **Encrypted**: 72 bytes
- **Working memory**: ~2KB
- **Total**: ~20KB

## Security Considerations

### Current Weaknesses

1. **Static keys**: Embedded in binary
2. **Custom crypto**: Not proven secure
3. **No authentication**: No MAC/HMAC
4. **Reversible**: XOR is symmetric
5. **Pattern-based**: Easy to find data

### Production Recommendations

1. Use AES-GCM or ChaCha20-Poly1305
2. Implement key derivation (PBKDF2/Argon2)
3. Use hardware security module (HSM)
4. Add code signing and attestation
5. Implement anti-tampering measures

## Debugging Tips

### Binary Debugging

```bash
# Check if binary runs
./harbor_binary_stripped

# Verify /app is writable
mkdir -p /app && chmod 777 /app

# Check output
cat /app/config.json
```

### Script Debugging

```bash
# Run with Python debugger
python3 -m pdb scripts/decrypt_config.py harbor_binary_stripped

# Add debug prints
# Edit script to add print statements

# Test without binary
python3 scripts/decrypt_config.py
```

### Common Issues

**Problem**: Binary can't write to `/app`  
**Solution**: Create directory with write permissions

**Problem**: Script can't find tables  
**Solution**: Check binary was built correctly, uses hardcoded fallback

**Problem**: Wrong output  
**Solution**: Rebuild from clean state: `make clean && make all`

## Conclusion

The Harbor implementation demonstrates a complete reverse engineering challenge with realistic obfuscation techniques. The modular design allows easy extension and modification for different evaluation scenarios.
