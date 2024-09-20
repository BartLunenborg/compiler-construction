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
	rm -f *~
	rm -f *.o
	rm -f parser.c
	rm -f parser.h
	rm -f lexer.c
	rm -f a.out
