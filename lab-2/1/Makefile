CC     = gcc
CFLAGS = -O2 -std=c99 -pedantic -Wall

all:
	make c

c: golf.c
	$(CC) $(CFLAGS) $^ $(LINK)

clean:
	rm -rf a.out
