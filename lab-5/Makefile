all: parser lexer strmap
	gcc -o minipas -O2 parser.o lexer.o strmap.o -lfl -lm -g

parser: parser.y
	bison -d parser.y
	mv parser.tab.c parser.c
	gcc -O2 -c parser.c -g

lexer: lexer.fl
	flex lexer.fl
	mv lex.yy.c lexer.c
	gcc -O2 -c lexer.c -g

strmap: strmap.c strmap.h
	gcc -O2 -c strmap.c -g

clean:
	rm -f *~
	rm -f *.o
	rm -f parser.c
	rm -f parser.tab.h
	rm -f lexer.c
	rm -f a.out
	rm -f minipas
