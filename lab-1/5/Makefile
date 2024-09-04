CC     = gcc
CFLAGS = -O2 -std=c99 -pedantic -Wall
LINK   = -lfl

all:
	make fl
	make c

fl: aabbb.fl
	flex $^

c: lex.yy.c
	$(CC) $(CFLAGS) $^ $(LINK)

clean:
	rm -rf a.out lex.yy.c
