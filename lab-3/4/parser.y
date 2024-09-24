%{
   #include <stdio.h>
   #include <stdlib.h>
   #include <math.h>

   #define YYSTYPE double

  extern int yylex (void);  /* scanner produced by flex */
  int yyerror(char *s);     /* forward declaration */
%}

%token NUMBER PLUS MINUS TIMES DIVIDE LEFTPAR RIGHTPAR POWER

%left  PLUS MINUS
%left  TIMES DIVIDE
%right POWER
%right NEG

%%

Expression: Expr { printf("%f\n", $1); }
          ;

Expr : NUMBER                { $$ = $1;          }
     | LEFTPAR Expr RIGHTPAR { $$ = $2;          }
     | Expr PLUS Expr        { $$ = $1 + $3;     }
     | Expr MINUS Expr       { $$ = $1 - $3;     }
     | Expr TIMES Expr       { $$ = $1 * $3;     }
     | Expr DIVIDE Expr      { $$ = $1 / $3;     }
     | Expr POWER Expr       { $$ = pow($1, $3); }
     | MINUS Expr            { $$ = -$2;         }
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
