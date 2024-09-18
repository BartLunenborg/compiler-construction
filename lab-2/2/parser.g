{
  #include <stdio.h>
  #include <stdlib.h>
  extern char *yytext;
  extern int pos;
}

%start LLparser, T;
%token CHAR_A, PLUS, TIMES,
       PARENL, PARENR, NEWLINE;
%options "generate-lexer-wrapper";
%lexical yylex;

T : S NEWLINE;
S : A B;
A : CHAR_A | PARENL S PARENR;
B : S | PLUS S | TIMES B |  ;

{

char input[100];
void LLmessage(int token) {
  printf("Syntax error: %s", input);
  for (int i = 0; i < pos + 13; i++) { printf("-"); }
  printf("^ unexpected symbol '%c'\n", yytext[0]);
  exit(0);
}

int main() {
  fgets(input, 100, stdin);
  yy_scan_string(input);
  LLparser();
  printf("SUCCESS\n");
  return 0;
}

}
