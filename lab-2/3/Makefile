all: parser lexer
	gcc parser.o lexer.o -lfl

parser: parser.g
	LLnextgen parser.g
	gcc -c parser.c

lexer: lexer.fl
	flex lexer.fl
	mv lex.yy.c lexer.c
	gcc -c lexer.c

clean:
	rm -rf a.out *.o parser.c parser.h lexer.c
