{
/**********************************************/
#include <stdio.h>
#include <stdlib.h>

extern char *yytext;
double stack[20];
int top = 0;  // always points to the first empty spot of the stack

// Pop x from stack, pop y from stack, push y+x
void add() {
  double x = stack[--top];
  stack[top-1] += x;
  printf("ADD\n");
}

// Pop x from stack, pop y from stack, push y-x
void sub() {
  double x = stack[--top];
  stack[top-1] -= x;
  printf("SUB\n");
}

// Pop x from stack, pop y from stack, push y*x
void mul() {
  double x = stack[--top];
  stack[top-1] *= x;
  printf("MUL\n");
}

// Pop x from stack, pop y from stack, push y/z
void divv() {
  double x = stack[--top];
  stack[top-1] /= x;
  printf("DIV\n");
}
/**********************************************/
}

%start LLparser, Expression;
%token NUMBER, PLUS, MINUS, TIMES, DIVIDE,
       LEFT_PARENTHESIS, RIGHT_PARENTHESIS;
%options "generate-lexer-wrapper";
%lexical yylex;


Expression
{char opp;}
    : Term [[PLUS | MINUS] {opp=yytext[0];} Term {opp == '+' ? add() : sub();}]*
    ;

Term
{char opp;}
    : Factor [[TIMES | DIVIDE] {opp=yytext[0];} Factor {opp == '*' ? mul() : divv();}]*
    ;

Factor
{double f;}
    : NUMBER {f = atof(yytext); printf("PUSH %g\n", f); stack[top++] = f;}
    | MINUS Factor {f = -1; printf("PUSH %g\n", f); stack[top++] = f; mul();}
    | LEFT_PARENTHESIS Expression RIGHT_PARENTHESIS
    ;


{
/*****************************************************************/
/* the following code is copied verbatim in the generated C file */

void LLmessage(int token) {
  printf("Syntax error....abort\n");
  exit(0);
}

int main() {
  LLparser();
  //printf("%lf\n", stack[0]);
  return 0;
}

/*****************************************************************/
}
