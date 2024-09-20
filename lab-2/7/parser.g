{
/**********************************************/
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

extern char *yytext;
extern int line_number;
double vals[26];
double *vars;

void error(char var) {
  printf("Error in line %d: variable '%c' has no initialized value.\n", line_number, var);
  exit(0);
}
/**********************************************/
}

%start LLparser, Input;
%token NUMBER, PLUS, MINUS, TIMES, DIVIDE, POWER,
       LEFT_PARENTHESIS, RIGHT_PARENTHESIS, NEWLINE,
       LET, VAR, EQUAL, SEMICOLON;
%options "generate-lexer-wrapper";
%lexical yylex;

Input
    : [Assignment | Evaluation]*
    ;

Assignment
{double val; char var;}
    : LET VAR {var=yytext[0];} 
      EQUAL Expression(&val) SEMICOLON 
      {vars[var-'a']=1; vals[var-'a']=val;}
    ;

Evaluation
{double val;}
    : Expression(&val) SEMICOLON {printf("%lf\n", val);}
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
    | VAR {char var = yytext[0]; 
      if (vars[var-'a']) {*f = vals[var-'a'];} else {error(var);}}
    | MINUS Factor(f) {*f = -(*f);}
    | LEFT_PARENTHESIS Expression(f) RIGHT_PARENTHESIS
    ;

{ /* the following code is copied verbatim in the generated C file */

void LLmessage(int token) {
  printf("Syntax error....abort\n");
  exit(-1);
}

int main() {
  vars = calloc(26, sizeof(double));
  LLparser();
  free(vars);
  return 0;
}

}
