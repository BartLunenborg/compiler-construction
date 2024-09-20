{
  #include <stdio.h>
  #include <stdlib.h>
}

%start LLparser, S;
%token CHAR_A, CHAR_B, CHAR_D, CHAR_E, CHAR_F;
%options "generate-lexer-wrapper";
%lexical yylex;

S   : A ;
A   : CHAR_A A3
    ;
A2  : CHAR_D A2
    | CHAR_E A2
    |
    ;
A3  : CHAR_B A4
    | CHAR_F CHAR_A A2
    | CHAR_A A2
    ;
A4  : B C CHAR_A CHAR_A A2
    | A B CHAR_A A2
    ;
B   : CHAR_B B C CHAR_A
    | CHAR_F
    ;
C   : CHAR_B A B
    |
    ;

{

char input[100];
void LLmessage(int token) {
  printf("FAILURE\n");
  exit(0);
}

int main() {
  LLparser();
  printf("SUCCESS\n");
  return 0;
}

}
