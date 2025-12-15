.PHONY: all clean build strip test

CC = gcc
CFLAGS = -Wall -O2
BINARY = harbor_binary
STRIPPED_BINARY = harbor_binary_stripped

all: build strip

build:
	$(CC) $(CFLAGS) src/harbor_binary.c -o $(BINARY)

strip: build
	strip -s $(BINARY) -o $(STRIPPED_BINARY)
	@echo "Stripped binary created: $(STRIPPED_BINARY)"

test: strip
	@echo "Testing stripped binary..."
	@mkdir -p /app
	@./$(STRIPPED_BINARY) || true
	@echo ""
	@echo "Testing decryption script..."
	@python3 scripts/decrypt_config.py $(STRIPPED_BINARY)

clean:
	rm -f $(BINARY) $(STRIPPED_BINARY)
	rm -rf /app/config.json
