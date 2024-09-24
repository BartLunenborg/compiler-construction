%{
  #include <stdio.h>
  #include <stdlib.h>

  extern int pos;
  extern char* yytext;
  char input[100];

  int yylex(void);

  void yyerror(const char *s);
  void yy_scan_string(const char *s);
%}

%token x y z

%%
S : A | B y | C C ;
A : C x A | x A | z |   ;
B : x C y | z C ;
C : x B x | C z | x z y | x y ;
%%

void yyerror(const char *msg) {
  printf("Syntax error: %s", input);
  for (int i = 0; i < pos + 13; i++) { printf("-"); }
  printf("^ unexpected symbol '%c'\n", yytext[0]);
  exit(0);
}

int main() {
  fgets(input, 100, stdin);
  yy_scan_string(input);
  yyparse();
  printf("SUCCESS\n");
  return 0;
}
