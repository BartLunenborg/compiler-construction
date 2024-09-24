%{
   #include <stdio.h>
   #include <stdlib.h>

   #define YYSTYPE double

  extern int yylex (void);  /* scanner produced by flex */
  int yyerror(char *s);     /* forward declaration */
%}

%token NUMBER PLUS MINUS TIMES DIVIDE LEFTPAR RIGHTPAR

%left  PLUS MINUS
%left  TIMES DIVIDE
%right NEG


%%
Expr : NUMBER  { printf("PUSH %lf\n", $1); }
     | LEFTPAR Expr RIGHTPAR
     | Expr PLUS Expr  { printf("ADD\n"); }
     | Expr MINUS Expr  { printf("SUB\n"); }
     | Expr TIMES Expr  { printf("MUL\n"); }
     | Expr DIVIDE Expr  { printf("DIV\n"); }
     | MINUS Expr  { printf("PUSH -1\nMUL\n"); }
     ;
%%

int yyerror(char *s) {
  printf("%s\n", s);
  exit(EXIT_SUCCESS);
}

int main() {
  yyparse();
  return 0;
}
