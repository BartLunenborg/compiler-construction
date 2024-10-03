all: parser lexer strtab
	gcc -o minipas -O2 parser.o lexer.o strtab.o -lfl -lm

parser: parser.y
	bison -d parser.y
	mv parser.tab.c parser.c
	gcc -O2 -c parser.c

lexer: lexer.fl
	flex lexer.fl
	mv lex.yy.c lexer.c
	gcc -O2 -c lexer.c

strtab: strtab.c strtab.h
	gcc -O2 -c strtab.c

clean:
	rm -f *~
	rm -f *.o
	rm -f parser.c
	rm -f parser.tab.h
	rm -f lexer.c
	rm -f a.out
	rm -f minipas
