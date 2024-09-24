%{
  #include <stdio.h>
  #include <stdlib.h>

  extern int pos;
  extern char* yytext;
  char input[100];

  int yylex(void);

  void yyerror(const char *s);
  void yy_scan_string(const char *s);

  int inside = 0;
  int nested = 0;
  int R = 0;  // Round  brackets
  int S = 0;  // Square brackets
  int C = 0;  // Curly  brackets
%}

%token RO RC SO SC CO CC

%%
S : RO { R++; inside++; } S RC { nested += --inside > 0; } S
  | SO { S++; inside++; } S SC { nested += --inside > 0; } S
  | CO { C++; inside++; } S CC { nested += --inside > 0; } S
  |
  ;
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
  printf(
    "SUCCESS\n"
    "(): %d\n"
    "[]: %d\n"
    "{}: %d\n"
    "nested: %d\n",
    R, S, C, nested
  );
  return 0;
}
