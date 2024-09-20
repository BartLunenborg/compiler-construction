{
/**********************************************/
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

extern char *yytext;
/**********************************************/
}

%start LLparser, Input;
%token NUMBER, PLUS, MINUS, TIMES, DIVIDE, POWER,
       LEFT_PARENTHESIS, RIGHT_PARENTHESIS, NEWLINE;
%options "generate-lexer-wrapper";
%lexical yylex;


Input
{double e;}
     : Expression(&e) {printf("%f\n", e);}
     ;

Expression(double *e)
{double t; int sign;}
    : Term(e) [[PLUS {sign=1;} | MINUS {sign=-1;}] Term(&t) {*e += sign*t;}]*
    ;

Term(double *t)
{double p; int op;}
    : Power(t) [[TIMES Power(&p) | DIVIDE Power(&p) {p = 1/p;}] {*t *= p;}]*
    ;

Power(double *p)
{double f;}
    : Factor(p) [POWER Power(&f) {*p = pow(*p, f);}]?
    ;

Factor(double *f)
    : NUMBER {*f = atof(yytext);}
    | MINUS Factor(f) {*f = -(*f);}
    | LEFT_PARENTHESIS Expression(f) RIGHT_PARENTHESIS
    ;

{ /* the following code is copied verbatim in the generated C file */

void LLmessage(int token) {
  printf("Syntax error....abort\n");
  exit(-1);
}

int main() {
  LLparser();
  return 0;
}

}
