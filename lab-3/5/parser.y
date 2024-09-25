%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>
  #include <math.h>

  #define YYSTYPE double
  #define YYERROR_VERBOSE 1
  #define YYDEBUG 1
  extern char* yytext;

  extern int yylineno;
  extern int yylex (void);  /* scanner produced by flex */
  int yyerror(char *s);     /* forward declaration */
%}

%token PROGRAM_ID DOT CONST ID EQUAL NUMBER COLON SEMICOLON
       SQUARE_OPEN SQUARE_CLOSE ROUND_OPEN ROUND_CLOSE
       COMMA VAR INTEGER REAL FUNCTION_ID SKIP IF ELSE
       PROCEDURE_ID OF BEG END ASSIGN WHILE DO
       THEN NOT AND OR RELOP READLN WRITELN ARRAY
       PLUS MINUS STAR SLASH DIV MOD
%left OR
%left AND
%right NOT
%left RELOP
%left PLUS MINUS
%left STAR SLASH DIV MOD
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
IdentifierLists :
                | IdentifierLists COMMA ID
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
Parameters      : ROUND_OPEN ParameterList ROUND_CLOSE
                ;
ParameterList   : VarOptional IdentifierList COLON TypeSpec ParameterLists
                ;
ParameterLists  :
                | ParameterLists SEMICOLON VarOptional IdentifierList COLON TypeSpec
                ;

CompoundStatement : BEG StatementListOptional END
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
                | READLN LhsList ROUND_CLOSE
                | WRITELN ArithExprList ROUND_CLOSE
                ;

ArithExprListOptional : ROUND_OPEN ArithExprList ROUND_CLOSE
                      |
                      ;
ArithExprList   : ArithExpr ArithExprLists
                ;
ArithExprLists  : ArithExprLists COMMA ArithExpr
                |
                ;
ArithExpr       : ID ArithExprOptional
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
ArithExprOptional : SQUARE_OPEN ArithExpr SQUARE_CLOSE
                  | SQUARE_OPEN ArithExpr DOT DOT ArithExpr SQUARE_CLOSE
                  |
                  ;
%%

int yyerror(char *s) {
  printf("PARSE ERROR (%d)\n", yylineno);
  exit(EXIT_SUCCESS);
}

int main() {
  //yydebug = 1;
  yyparse();
  printf("ACCEPTED\n");
  return 0;
}
