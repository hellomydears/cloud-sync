CC=gcc
CFLAGS=-Wall -O2
TARGET=funny.bin

all: $(TARGET)

$(TARGET): src/main.c
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f $(TARGET)

.PHONY: all clean
