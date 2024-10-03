%{

  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>
  #include "strtab.h"

  void yyerror(char *msg);    /* forward declaration */
  /* exported by the lexer (made with flex) */
  extern int yylex(void);
  extern char *yytext;
  extern void showErrorLine();
  extern void initLexer(FILE *f);
  extern void finalizeLexer();

%}

%token PROGRAM CONST IDENTIFIER VAR ARRAY RANGE INTNUMBER REALNUMBER OF
       FUNCTION PROCEDURE BEGINTOK ENDTOK ASSIGN IF THEN ELSE WHILE DO
       RELOPLT RELOPLEQ RELOPEQ RELOPNEQ RELOPGEQ RELOPGT INTEGER REAL
       AND OR NOT DIV MOD SKIP READLN WRITELN

%left '+' '-'
%left '*' '/' DIV MOD
%left OR
%left AND
%left NOT

%union {
  int ival;     /* used for passing int values from lexer to parser */
  double dval;  /* used for passing double values from lexer to parser */
  /* add here anything you may need */
  /*....*/
}


%%

program            : PROGRAM IDENTIFIER ';'
                     ConstDecl
                     VarDecl
                     FuncProcDecl
                     CompoundStatement
                     '.'
                   ;

ConstDecl          : ConstDecl CONST IDENTIFIER RELOPEQ NumericValue ';'
                   | %empty
                   ;

NumericValue       : INTNUMBER
                   | REALNUMBER
                   ;

VarDecl            : VarDecl VAR IdentifierList ':' TypeSpec ';'
                   | %empty
                   ;

IdentifierList     : IDENTIFIER
                   | IdentifierList ',' IDENTIFIER
                   ;

TypeSpec           : BasicType
                   | ARRAY '[' INTNUMBER RANGE INTNUMBER ']' OF BasicType
                   ;

BasicType          : INTEGER
                   | REAL
                   ;

FuncProcDecl       : FuncProcDecl SubProgDecl ';'
                   | %empty
                   ;

SubProgDecl        : SubProgHeading VarDecl CompoundStatement
                   ;

SubProgHeading     : FUNCTION IDENTIFIER Parameters ':' BasicType ';'
                   | PROCEDURE IDENTIFIER PossibleParameters ';'
                   ;

PossibleParameters : Parameters
                   | %empty
                   ;

Parameters         : '(' ParameterList ')'
                   ;

ParameterList      : ParamList
                   | ParameterList ';' ParamList
                   ;

ParamList          : VAR IdentifierList ':' TypeSpec
                   | IdentifierList ':' TypeSpec
                   ;

CompoundStatement  : BEGINTOK OptionalStatements ENDTOK
                   ;

OptionalStatements : StatementList
                   | %empty
                   ;

StatementList      : Statement
                   | StatementList ';' Statement
                   ;

Statement          : Lhs ASSIGN ArithExpr
                   | SKIP
                   | ProcedureCall
                   | CompoundStatement
                   | IF Guard THEN Statement ELSE Statement
                   | WHILE Guard DO Statement
                   ;

LhsList            : Lhs
                   | LhsList ',' Lhs

Lhs                : IDENTIFIER
                   | IDENTIFIER '[' ArithExpr ']'
                   ;

ProcedureCall      : IDENTIFIER
                   | IDENTIFIER '(' ArithExprList ')'
                   | READLN '(' LhsList ')'
                   | WRITELN '(' ArithExprList ')'
                   ;

Guard              : BoolAtom
                   | NOT Guard
                   | Guard OR Guard
                   | Guard AND Guard
                   | '(' Guard ')'
                   ;

BoolAtom           : ArithExpr Relop ArithExpr
                   ;

Relop              : RELOPLT
                   | RELOPLEQ
                   | RELOPEQ
                   | RELOPNEQ
                   | RELOPGEQ
                   | RELOPGT
                   ;

ArithExprList      : ArithExpr
                   | ArithExprList ',' ArithExpr
                   ;

ArithExpr          : IDENTIFIER
                   | IDENTIFIER '[' ArithExpr ']'
                   | IDENTIFIER '[' ArithExpr RANGE ArithExpr ']'
                   | IDENTIFIER '(' ArithExprList ')'
                   | INTNUMBER
                   | REALNUMBER
                   | ArithExpr '+' ArithExpr
                   | ArithExpr '-' ArithExpr
                   | ArithExpr '*' ArithExpr
                   | ArithExpr '/' ArithExpr
                   | ArithExpr DIV ArithExpr
                   | ArithExpr MOD ArithExpr
                   | '-' ArithExpr
                   | '(' ArithExpr ')'
                   ;

%%

void printToken(int token, FILE *f) {
  /* single character tokens */
  if (token < 256) {
    if (token < 33) {
      /* non-printable character */
      fprintf(f, "chr(%d)", token);
    } else {
      fprintf(f, "'%c'", token);
    }
    return;
  }
  /* standard tokens (>255) */
  switch (token) {
    case PROGRAM   : fprintf(f, "PROGRAM"); break;
    case CONST     : fprintf(f, "CONST"); break;
    case IDENTIFIER: fprintf(f, "identifier<%s>", yytext); break;
    case VAR       : fprintf(f, "VAR"); break;
    case ARRAY     : fprintf(f, "ARRAY"); break;
    case RANGE     : fprintf(f, ".."); break;
    case INTNUMBER : fprintf(f, "Integer<%d>", yylval.ival); break;
    case REALNUMBER: fprintf(f, "Real<%lf>", yylval.dval); break;
    case OF        : fprintf(f, "OF"); break;
    case INTEGER   : fprintf(f, "INTEGER"); break;
    case REAL      : fprintf(f, "REAL"); break;
    case FUNCTION  : fprintf(f, "FUNCTION"); break;
    case PROCEDURE : fprintf(f, "PROCEDURE"); break;
    case BEGINTOK  : fprintf(f, "BEGIN"); break;
    case ENDTOK    : fprintf(f, "END"); break;
    case ASSIGN    : fprintf(f, ":="); break;
    case IF        : fprintf(f, "IF"); break;
    case THEN      : fprintf(f, "THEN"); break;
    case ELSE      : fprintf(f, "ELSE"); break;
    case WHILE     : fprintf(f, "WHILE"); break;
    case DO        : fprintf(f, "DO"); break;
    case SKIP      : fprintf(f, "SKIP"); break;
    case READLN    : fprintf(f, "READLN"); break;
    case WRITELN   : fprintf(f, "WRITELN"); break;
  }
}

void yyerror (char *msg) {
  showErrorLine();
  fprintf(stderr, "%s (detected at token=", msg);
  printToken(yychar, stderr);
  fprintf(stderr, ").\n");

  printf("ERRORS: 1\nREJECTED\n");
  exit(EXIT_SUCCESS);  /* EXIT_SUCCESS because we use Themis */
}

int main(int argc, char *argv[]) {
  if (argc != 2) {
    fprintf(stderr, "Usage: %s [pasfile]\n", argv[0]);
    return EXIT_FAILURE;
  }

  FILE *input = (strcmp(argv[1], "-") == 0) ? stdin : fopen(argv[1], "r");
  if(input == NULL) {
    fprintf(stderr, "Failed to open input file!\n");
    exit(EXIT_FAILURE);
  }

  initLexer(input);
  int result = yyparse();
  finalizeLexer();

#if 0
  showStringTable();
#endif

  printf("ERRORS: %d\n", 0);
  puts(result == 0 ? "ACCEPTED" : "REJECTED");

  fclose(input);

  return EXIT_SUCCESS;
}
