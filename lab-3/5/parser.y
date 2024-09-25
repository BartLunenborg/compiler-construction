%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>
  #include <math.h>

  #define YYSTYPE double
  extern char* yytext;

  extern int yylineno;      /* Use the line number option from flex */
  extern int yylex (void);  /* scanner produced by flex */
  int yyerror(char *s);     /* forward declaration */
%}

%token PROGRAM_ID FUNCTION_ID PROCEDURE_ID
       CONST VAR INTEGER REAL
       IF THEN ELSE DO WHILE SKIP 
       BEG END ARRAY OF
       ASSIGN EQUAL RELOP NOT AND OR
       PLUS MINUS STAR SLASH DIV MOD
       DOT COMMA COLON SEMICOLON
       ROUND_OPEN ROUND_CLOSE
       SQUARE_OPEN SQUARE_CLOSE
       ID NUMBER READLN WRITELN

%left  OR
%left  AND
%right NOT
%left  RELOP
%left  PLUS MINUS
%left  STAR SLASH DIV MOD

%%

Program         : PROGRAM_ID SEMICOLON
                  ConstDecls
                  VarDecls
                  FuncProcDecls
                  CompoundStatement DOT
                ;

ConstDecls      : ConstDecls ConstDecl
                |
                ;
ConstDecl       : CONST ID EQUAL NUMBER SEMICOLON
                ;

VarOptional     : VAR
                |
                ;

VarDecls        : VarDecls VarDecl
                |
                ;
VarDecl         : VAR IdentifierList COLON TypeSpec SEMICOLON
                ;

IdentifierList  : ID IdentifierLists
                ;
IdentifierLists : IdentifierLists COMMA ID
                |
                ;

TypeSpec        : BasicType
                | ARRAY SQUARE_OPEN NUMBER DOT DOT NUMBER SQUARE_CLOSE OF BasicType
                ;
BasicType       : INTEGER
                | REAL
                ;

FuncProcDecls   : FuncProcDecls FuncProcDecl
                |
                ;
FuncProcDecl    : FUNCTION_ID Parameters COLON BasicType SEMICOLON VarDecls CompoundStatement SEMICOLON
                | PROCEDURE_ID ParametersOptional SEMICOLON VarDecls CompoundStatement SEMICOLON
                ;

ParametersOptional : Parameters
                   |
                   ;
Parameters         : ROUND_OPEN ParameterList ROUND_CLOSE
                   ;
ParameterList      : VarOptional IdentifierList COLON TypeSpec ParameterLists
                   ;
ParameterLists     : ParameterLists SEMICOLON VarOptional IdentifierList COLON TypeSpec
                   |
                   ;

CompoundStatement     : BEG StatementListOptional END
                      ;
StatementListOptional : StatementList
                      |
                      ;
StatementList         : Statement Statements
                      ;
Statements            : Statements SEMICOLON Statement
                      |
                      ;

Statement       : Lhs ASSIGN ArithExpr
                | ProcedureCall
                | CompoundStatement
                | SKIP
                | IF Guard THEN Statement ELSE Statement
                | WHILE Guard DO Statement
                ;
Guard           : BoolAtom
                | NOT Guard
                | Guard OR Guard
                | Guard AND Guard
                | ROUND_OPEN Guard ROUND_CLOSE
                ;
BoolAtom        : ArithExpr RELOP ArithExpr
                ;

LhsList         : Lhs Lhss
                ;
Lhss            : Lhss COMMA Lhs
                |
                ;
Lhs             : ID ArithExprOptional
                ;

ProcedureCall   : ID ArithExprListOptional
                | READLN ROUND_OPEN LhsList ROUND_CLOSE
                | WRITELN ROUND_OPEN ArithExprList ROUND_CLOSE
                ;

ArithExprListOptional : ROUND_OPEN ArithExprList ROUND_CLOSE
                      |
                      ;
ArithExprList         : ArithExpr ArithExprLists
                      ;
ArithExprLists        : ArithExprLists COMMA ArithExpr
                      |
                      ;

ArithExprOptional : SQUARE_OPEN ArithExpr SQUARE_CLOSE
                  | SQUARE_OPEN ArithExpr DOT DOT ArithExpr SQUARE_CLOSE
                  |
                  ;
ArithExpr         : ID ArithExprOptional
                  | NUMBER
                  | ID ROUND_OPEN ArithExprList ROUND_CLOSE
                  | ArithExpr PLUS ArithExpr
                  | ArithExpr MINUS ArithExpr
                  | ArithExpr STAR ArithExpr
                  | ArithExpr SLASH ArithExpr
                  | ArithExpr DIV ArithExpr
                  | ArithExpr MOD ArithExpr
                  | MINUS ArithExpr
                  | ROUND_OPEN ArithExpr ROUND_CLOSE
                  ;
%%

int yyerror(char *s) {
  printf("PARSE ERROR (%d)\n", yylineno);
  exit(EXIT_SUCCESS);
}

int main() {
  yyparse();
  printf("ACCEPTED\n");
  return 0;
}
