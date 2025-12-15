#!/usr/bin/env python3
import sys

data = open('harbor_binary_stripped', 'rb').read()
sig = bytes([0x58, 0xff, 0xba, 0x35, 0x49, 0x41])
idx = data.find(sig)
print(f'Encrypted data found at offset: {idx}')

if idx != -1:
    print(f'Bytes at offset: {data[idx:idx+20].hex()}')
