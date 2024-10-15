%{

  #include "strmap.h"
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>

  void yyerror(char *msg);    /* forward declaration */
  /* exported by the lexer (made with flex) */
  extern int yylex(void);
  extern char *yytext;
  extern void showErrorLine();
  extern void initLexer(FILE *f);
  extern void finalizeLexer();
    
  ArithExprList **lists = NULL;
  int listDepth = 0;


  int ERRORS = 0;
  int scope = 0;             // 0 = in global scope, 1 = in local scope
  HashMap *maps[2];          // maps[0] is the global scope, maps[1] is the local scope
  char *currentFunc = NULL;  // If declaring a function set the name for easy access

  /*  ==============  ERRORS  ==============  */
  // Redefinition of an IDENTIFIER error
  void redefinitionError(char *str) {
    fprintf(stderr, "Error: redefinition of '%s'!\n", str);
    showErrorLine();
    ERRORS++;
  }

  void constAsRefError() {
    fprintf(stderr, "Error: trying to pass a 'const' variable as reference!\n");
    showErrorLine();
    ERRORS++;
  }
  
  void funcAsRefError() {
    fprintf(stderr, "Error: trying to pass a function as reference!\n");
    showErrorLine();
    ERRORS++;
  }

  void returnValIgnoredError(char *str) {
    fprintf(stderr, "Error: return value of '%s' is ignored!\n", str);
    showErrorLine();
    ERRORS++;
  }

  // Using an unknown IDENTIFIER error
  void undeclaredError(char *str) {
    fprintf(stderr, "Error: '%s' undeclared, first used in:\n", str);
    showErrorLine();
    ERRORS++;
  }

  // Assignment to a CONST variable error
  void constAssignError(char *str, int type) {
    fprintf(stderr, "Error: '%s' is declared as '%s', assignment not allowed!\n", str, typeAsString(type));
    showErrorLine();
    ERRORS++;
  }

  // Using non-integer types in mod operator
  void moduloError(int type) {
    fprintf(stderr, 
      "Error: trying to use an expression of type '%s' in modulo operator!\n"
      "'mod' is only defined for integer types.\n", typeAsString(type)
    );
    showErrorLine();
    ERRORS++;
  }

  // Using non-integer types in div operator
  void divError(int type) {
    fprintf(stderr, 
      "Error: trying to use an expression of type '%s' in div operator!\n"
      "'div' is only defined for integer types.\n", typeAsString(type)
    );
    showErrorLine();
    ERRORS++;
  }

  void funcShadowedError(char *str) {
    fprintf(stderr, "Error: Trying to call '%s', but '%s' is shadowed by a local variable!\n", str, str);
    showErrorLine();
    ERRORS++;
  }
  
  // Trying to use an invalid type in rhs of assignment
  void invalidRhsError(int type) {
    fprintf(stderr, "Error: Cannot assign a '%s' to a variable!\n", typeAsString(type));
    showErrorLine();
    ERRORS++;
  }

  // Trying to index an array with a non-int
  void invalidIndexTypeError(int type) {
    fprintf(stderr, "Error: Cannot index an array with a type '%s'!\n", typeAsString(type));
    showErrorLine();
    ERRORS++;
  } 

  // Trying to use something that has no value
  void noValueError(int type) {
    fprintf(stderr, "Error: type '%s' does not have a value and can't be used in this context!\n", typeAsString(type));
    showErrorLine();
    ERRORS++;
  }

  // Trying to divide by 0
  void divisionByZeroError() {
    fprintf(stderr, "Error: division by zero is not allowed!\n");
    showErrorLine();
    ERRORS++;
  }

  // Trying to modulo by 0
  void modByZeroError() {
    fprintf(stderr, "Error: modulo by zero is not allowed!\n");
    showErrorLine();
    ERRORS++;
  }

  // Trying to assign a real to an int
  void truncationError() {
    fprintf(stderr, "Error: trying to assign a 'REAL' number to an 'INTEGER' will result in truncation!\n");
    showErrorLine();
    ERRORS++;
  }

  // Trying to call a function with the wrong number of arguments
  void wrongNumArgumentsError(char *func, int expected, int actual) {
    fprintf(stderr, "Error: '%s' expects '%d' arguments, but was given '%d'!\n", func, expected, actual);
    showErrorLine();
    ERRORS++;
  }

  void wrongArgumentTypeError(char *func, int i, int expected, int actual) {
    fprintf(stderr, "Error: argument '%d' of '%s' should be of type '%s', but got '%s'!\n", i, func, typeAsString(expected), typeAsString(actual));
    showErrorLine();
    ERRORS++;
  }

  void outOfBoundsError(char *arr, const char *arrBounds, int index) {
    fprintf(stderr, "Error: '%d' is outside of the bounds of '%s' which are %s!\n", index, arr, arrBounds);
    showErrorLine();
    ERRORS++;
  }
  
  void invalidRangeError(int lower, int upper) {
    fprintf(stderr, "Error: a range of [%d..%d] is not valid for and array! (lower must be <= upper)\n", lower, upper);
    showErrorLine();
    ERRORS++;
  }

  void negativeIndexError(int idx) {
    fprintf(stderr, "Error: an index %d is not valid for and array! (must bet >= 0)\n", idx);
    showErrorLine();
    ERRORS++;
  }

  void wrongRangeError(char *func, int i, int eLower, int eUpper, int aLower, int aUpper) {
    fprintf(stderr, "Error: argument '%d' of '%s' expects and array of length '%d' but got an array of length '%d'!\n", i, func, eUpper - eLower + 1, aUpper - aLower + 1);
    showErrorLine();
    ERRORS++;
  }

  void invalidRelopArithExpr(int type, char *relop) {
    fprintf(stderr, "Error: cannot use something of type '%s' with the relational operator '%s'\n", typeAsString(type), relop);
    showErrorLine();
    ERRORS++;
  }

  void invalidProcCallError(int type) {
    fprintf(stderr, "Error: cannot call something of type '%s' as a PROCEDURE\n", typeAsString(type));
    showErrorLine();
    ERRORS++;
  }

  void invalidFuncCallError(int type) {
    fprintf(stderr, "Error: cannot call something of type '%s' as a FUNCTION\n", typeAsString(type));
    showErrorLine();
    ERRORS++;
  }

  void nonArrayError(int type) {
    fprintf(stderr, "Error: cannot use something of type '%s' as an array\n", typeAsString(type));
    showErrorLine();
    ERRORS++;
  }

  void invalidLhsError(int type) {
    fprintf(stderr, "Error: cannot use something of type '%s' as a LHS in this context\n", typeAsString(type));
    showErrorLine();
    ERRORS++;
  }
  
  void invalidWritelnTypeError(int type) {
    fprintf(stderr, "Error: cannot use something of type '%s' in writeln\n", typeAsString(type));
    showErrorLine();
    ERRORS++;
  }
%}

%union {
  int ival;     /* used for passing int values from lexer to parser    */
  double dval;  /* used for passing double values from lexer to parser */
  char* id;     /* used for passing char* values from lexer to parser  */
  struct {
    double val;
    int type;
    int lower;
    int upper;
    int valKnown;
  } numeric;
  struct {
    int type;
    int array;
    int lower;
    int upper;
  } typeSpec;
  int type;
}

%token PROGRAM CONST VAR ARRAY RANGE OF
       FUNCTION PROCEDURE BEGINTOK ENDTOK ASSIGN IF THEN ELSE WHILE DO
       RELOPLT RELOPLEQ RELOPEQ RELOPNEQ RELOPGEQ RELOPGT INTEGER REAL
       AND OR NOT DIV MOD SKIP READLN WRITELN

%token <id>   IDENTIFIER
%token <ival> INTNUMBER
%token <dval> REALNUMBER

%type <numeric>    NumericValue ArithExpr Lhs
%type <type>       BasicType
%type <typeSpec>   TypeSpec
%type <id>         IdentifierList Relop

%left '+' '-'
%left '*' '/' DIV MOD
%left OR
%left AND
%left NOT

%%

program            : PROGRAM IDENTIFIER { free($2); } ';'
                     ConstDecl 
                     VarDecl
                     FuncProcDecl
                     CompoundStatement
                     '.'
                   ;

ConstDecl          : ConstDecl CONST IDENTIFIER RELOPEQ NumericValue ';' {
                      if (lookupStringTable(maps[scope], $3) == -1) {  // new CONST
                        int idx = insertOrRetrieveStringTable(maps[scope], $3);
                        setType(maps[scope], idx, $5.type);
                        setVal(maps[scope], idx, $5.val);
                      } else {  // Duplicate CONST
                        redefinitionError($3);
                      }
                      free($3);
                     }
                   | %empty
                   ;

NumericValue       : INTNUMBER   { $$.val = $1; $$.type = INTCON;  }
                   | REALNUMBER  { $$.val = $1; $$.type = REALCON; }
                   ;

VarDecl            : VarDecl VAR IdentifierList ':' TypeSpec ';' {
                      if ($5.array) {
                        assignArrayTypes(maps[scope], $5.type, $5.lower, $5.upper);
                      } else {
                        assignTypes(maps[scope], $5.type);
                      }
                     }
                   | %empty
                   ;

IdentifierList     : IDENTIFIER {
                      if (lookupStringTable(maps[scope], $1) == -1 && !(currentFunc && strcmp($1, currentFunc) == 0)) {
                        insertOrRetrieveStringTable(maps[scope], $1);
                      } else {
                        redefinitionError($1);  // Duplicate Identifier
                      }
                      free($1);
                     }
                   | IdentifierList ',' IDENTIFIER {
                      if (lookupStringTable(maps[scope], $3) == -1 && !(currentFunc && strcmp($1, currentFunc) == 0)) {
                        insertOrRetrieveStringTable(maps[scope], $3);
                      } else {
                        redefinitionError($3);  // Duplicate Identifier
                      }
                      free($3);
                     }
                   ;

TypeSpec           : BasicType  { $$.type = $1; $$.array = 0; }
                   | ARRAY '[' INTNUMBER RANGE INTNUMBER ']' OF BasicType {
                      if ($5 < $3) {
                        invalidRangeError($3, $5);
                      }
                      if ($3 < 0) {
                        negativeIndexError($3);
                      }
                      if ($5 < 0) {
                        negativeIndexError($3);
                      }
                      $$.type = $8; $$.array = 1; $$.lower = $3; $$.upper = $5;
                     }
                   ;

BasicType          : INTEGER  { $$ = INTNUM;  }
                   | REAL     { $$ = REALNUM; }
                   ;

FuncProcDecl       : FuncProcDecl SubProgDecl ';'
                   | %empty
                   ;

SubProgDecl        : { maps[++scope] = newStringTable(); } SubProgHeading VarDecl CompoundStatement { 
                      freeStringTable(maps[scope]); maps[scope--] = NULL; 
                     }
                   ;

SubProgHeading     : FUNCTION IDENTIFIER { 
                      currentFunc = $2; 
                      if (lookupStringTable(maps[0], currentFunc) == -1) {
                        insertOrRetrieveStringTable(maps[0], currentFunc); 
                      } else {
                        redefinitionError(currentFunc);
                      }
                     } Parameters ':' BasicType ';' { 
                      setType(maps[0], lookupStringTable(maps[0], currentFunc), ($6 == INTNUM ? FUNCI : FUNCR));
                      copyToLocalScope(maps[0], maps[1], currentFunc);
                      free(currentFunc); currentFunc = NULL;
                     }
                   | PROCEDURE IDENTIFIER {
                      currentFunc = $2;
                      if (lookupStringTable(maps[0], currentFunc) == -1) {
                        int idx = insertOrRetrieveStringTable(maps[0], currentFunc);
                        setType(maps[0], idx, PROC);
                      } else {
                        redefinitionError(currentFunc);
                      }
                     } PossibleParameters ';' { free(currentFunc); currentFunc = NULL; }
                   ;

PossibleParameters : Parameters
                   | %empty
                   ;

Parameters         : '(' ParameterList ')'
                   ;

ParameterList      : ParamList
                   | ParameterList ';' ParamList
                   ;

ParamList          : VAR IdentifierList ':' TypeSpec {
                      int vars = 0; int type = $4.type;
                      if ($4.array) {
                        vars = assignArrayTypes(maps[scope], $4.type, $4.lower, $4.upper);
                        type = $4.type == REALNUM ? ARROR : ARROI;
                      } else {
                        vars = assignTypes(maps[scope], $4.type);
                      }
                      addParams(maps[0], currentFunc, vars, type, $4.lower, $4.upper, 1);
                     }
                   | IdentifierList ':' TypeSpec {
                      int vars = 0; int type = $3.type;
                      if ($3.array) {
                        vars = assignArrayTypes(maps[scope], $3.type, $3.lower, $3.upper);
                        type = $3.type == REALNUM ? ARROR : ARROI;
                      } else {
                        vars = assignTypes(maps[scope], $3.type);
                      }
                      addParams(maps[0], currentFunc, vars, type, $3.lower, $3.upper, 0);
                     }
                   ;

CompoundStatement  : BEGINTOK OptionalStatements ENDTOK
                   ;

OptionalStatements : StatementList
                   | %empty
                   ;

StatementList      : Statement
                   | StatementList ';' Statement
                   ;

Statement          : Lhs ASSIGN ArithExpr { 
                      if (!typeCanBeRhs($3.type)) {
                        invalidRhsError($3.type); 
                      }
                      if (isIntegerType($1.type) && isRealType($3.type)) {
                        truncationError();
                      }
                     }
                   | SKIP
                   | ProcedureCall
                   | CompoundStatement
                   | IF Guard THEN Statement ELSE Statement
                   | WHILE Guard DO Statement
                   ;

LhsList            : Lhs
                   | LhsList ',' Lhs

Lhs                : IDENTIFIER {
                      int idx = lookupStringTable(maps[scope], $1);
                      if (idx == -1 && (scope != 1 || lookupStringTable(maps[0], $1) == -1)) {
                        undeclaredError($1);
                      } else {
                        int scopeFound = idx == -1 ? 0 : scope;
                        idx = lookupStringTable(maps[scopeFound], $1);
                        if (isConstantType(maps[scopeFound], idx)) {
                          constAssignError($1, typeFromIdx(maps[scopeFound], idx));
                        } else if (!canBeLhs(maps[scopeFound], idx, scope)) {
                          invalidLhsError(typeFromIdx(maps[scopeFound], idx));
                        } else if (scope != scopeFound && isFuncType(maps[scopeFound], idx)) {
                          invalidLhsError(typeFromIdx(maps[scopeFound], idx));
                        }
                        $$.type = typeFromIdx(maps[scopeFound], idx);
                      }
                      free($1);
                     }
                   | IDENTIFIER '[' ArithExpr ']' {
                      int idx = lookupStringTable(maps[scope], $1);
                      $$.valKnown = 0;
                      if (idx == -1 && (scope != 1 || lookupStringTable(maps[0], $1) == -1)) {
                        undeclaredError($1);
                      } else if (!isIntegerType($3.type)) {
                        invalidIndexTypeError($3.type);
                      } else {
                        int scopeFound = idx == -1 ? 0 : scope;
                        idx = lookupStringTable(maps[scopeFound], $1);
                        if (!isArrayType(maps[scopeFound], idx)) {
                          nonArrayError(typeFromIdx(maps[scopeFound], idx));
                        } else if ($3.valKnown && $3.val < 0) {
                          negativeIndexError($3.val);
                        } else if ($3.valKnown && !isInRange(maps[scopeFound], idx, $3.val)) {
                          outOfBoundsError($1, arrBoundsAsString(maps[scopeFound], idx), $3.val);
                        }
                        $$.type = typeFromArr(typeFromStr(maps[scopeFound], $1));
                      }
                      free($1);
                     }
                   ;

ProcedureCall      : IDENTIFIER {
                      int idx = lookupStringTable(maps[0], $1);
                      if (idx == -1) {
                        undeclaredError($1);
                      } else if (scope == 1 && lookupStringTable(maps[1], $1) > -1 && !isFuncType(maps[1], lookupStringTable(maps[1], $1))) {
                        funcShadowedError($1);
                      } else if (typeFromIdx(maps[0], idx) != PROC) {
                        invalidProcCallError(typeFromIdx(maps[0], idx));
                      } else if (expectedNumArguments(maps[0], $1) != 0) {
                        wrongNumArgumentsError($1, expectedNumArguments(maps[0], $1), 0);
                      }
                      free($1);
                     }
                   | IDENTIFIER { lists = addList(lists, ++listDepth); } '(' ArithExprList ')' {
                      int idx = lookupStringTable(maps[0], $1);
                      int expected = expectedNumArguments(maps[0], $1);
                      if (idx == -1) {
                        undeclaredError($1);
                      } else if (scope == 1 && lookupStringTable(maps[1], $1) > -1 && !isFuncType(maps[1], lookupStringTable(maps[1], $1))) {
                        funcShadowedError($1);
                      } else if (!isFuncType(maps[0], idx)) {
                        invalidFuncCallError(typeFromIdx(maps[0], idx));
                      } else if (expected != lists[listDepth-1]->len) {
                          wrongNumArgumentsError($1, expected, lists[listDepth-1]->len);
                      } else {
                        if (typeFromIdx(maps[0], idx) != PROC) {
                          returnValIgnoredError($1);
                        }
                        for (int i = 0; i < expected; i++) {
                          int expectedType = maps[0]->symbols[idx].params[i].type;
                          int actualType = lists[listDepth-1]->items[i].type;
                          if (!isValidParamType(maps[0]->symbols[idx].params[i], lists[listDepth-1]->items[i])) {
                            if (typeGetsTruncated(maps[0]->symbols[idx].params[i], lists[listDepth-1]->items[i])) {
                              truncationError();
                            } else { wrongArgumentTypeError($1, i, expectedType, actualType); }
                          } else if (!isValidArraySlice(maps[0]->symbols[idx].params[i], lists[listDepth-1]->items[i])) {
                            Param e = maps[0]->symbols[idx].params[i];
                            ArithExprItem a = lists[listDepth-1]->items[i];
                            wrongRangeError($1, i, e.lower, e.upper, a.lower, a.upper);
                          }
                          int isRef = maps[0]->symbols[idx].params[i].ref;
                          if (isRef && (actualType == REALCON || actualType == INTCON)) { constAsRefError(); }
                          if (isRef && (actualType == FUNCI || actualType == FUNCR)) { funcAsRefError(); }
                        }
                      }
                      lists = freeList(lists, --listDepth);
                      free($1);
                     }
                   | READLN '(' LhsList ')'
                   | WRITELN { lists = addList(lists, ++listDepth); } '(' ArithExprList ')' {
                      int len = lists[listDepth-1]->len;
                      for (int i = 0; i < len; i++) {
                        int type = lists[listDepth-1]->items[i].type;
                        if (!typeCanBeRhs(type)) {
                          invalidWritelnTypeError(type);
                        }
                      }
                      lists = freeList(lists, --listDepth);
                     }
                   ;

Guard              : BoolAtom
                   | NOT Guard
                   | Guard OR Guard
                   | Guard AND Guard
                   | '(' Guard ')'
                   ;

BoolAtom           : ArithExpr Relop ArithExpr {
                      if (!isRealType($1.type) && !isIntegerType($1.type)) {
                        invalidRelopArithExpr($1.type, $2); 
                      }
                      if (!isRealType($3.type) && !isIntegerType($3.type)) {
                        invalidRelopArithExpr($3.type, $2); 
                      }
                     }  
                   ;

Relop              : RELOPLT   { $$ = "<" ; }
                   | RELOPLEQ  { $$ = "<="; }
                   | RELOPEQ   { $$ = "=" ; }
                   | RELOPNEQ  { $$ = "<>"; }
                   | RELOPGEQ  { $$ = ">="; }
                   | RELOPGT   { $$ = ">" ; }
                   ;

ArithExprList      : ArithExpr  { addArithExpr(lists, listDepth-1, $1.type, $1.val, $1.lower, $1.upper); }
                   | ArithExprList ',' ArithExpr { addArithExpr(lists, listDepth-1, $3.type, $3.val, $3.lower, $3.upper); }
                   ;

ArithExpr          : IDENTIFIER {
                      int idx = lookupStringTable(maps[scope], $1); $$.valKnown = 0;
                      if (idx == -1 && (scope != 1 || lookupStringTable(maps[0], $1) == -1)) {
                        undeclaredError($1);
                      } else {
                        int scopeFound = idx == -1 ? 0 : scope;
                        idx = lookupStringTable(maps[scopeFound], $1);
                        $$.type = typeFromStr(maps[scopeFound], $1);
                        $$.lower = maps[scopeFound]->symbols[idx].lower; $$.upper = maps[scopeFound]->symbols[idx].upper;
                        $$.val = -1;
                      }
                      free($1);
                     }
                   | IDENTIFIER '[' ArithExpr ']' {
                      int idx = lookupStringTable(maps[scope], $1);
                      $$.valKnown = 0;
                      if (idx == -1 && (scope != 1 || lookupStringTable(maps[0], $1) == -1)) {
                        undeclaredError($1);
                      } else if (!isIntegerType($3.type)) {
                        invalidIndexTypeError($3.type);
                      } else {
                        int scopeFound = idx == -1 ? 0 : scope;
                        idx = lookupStringTable(maps[scopeFound], $1);
                        if (!isArrayType(maps[scopeFound], idx)) {
                          nonArrayError(typeFromIdx(maps[scopeFound], idx));
                        } else if ($3.valKnown && $3.val < 0) {
                          negativeIndexError($3.val);
                        } else if ($3.valKnown && !isInRange(maps[scopeFound], idx, $3.val)) {
                          outOfBoundsError($1, arrBoundsAsString(maps[scopeFound], idx), $3.val);
                        }
                        $$.type = typeFromArr(typeFromStr(maps[scopeFound], $1));
                      }
                      free($1);
                     }
                   | IDENTIFIER '[' INTNUMBER RANGE INTNUMBER ']' {
                      int idx = lookupStringTable(maps[scope], $1);
                      $$.valKnown = 0;
                      if (idx == -1 && (scope != 1 || lookupStringTable(maps[0], $1) == -1)) {
                        undeclaredError($1);
                      } else if ($5 < $3) {
                        invalidRangeError($3, $5);
                      } else if ($3 < 0 || $5 < 0) {
                        if ($3 < 0) {
                          negativeIndexError($3);
                        }
                        if ($5 < 0) {
                          negativeIndexError($5);
                        }
                      } else {
                        int scopeFound = idx == -1 ? 0 : scope;
                        idx = lookupStringTable(maps[scopeFound], $1);
                        if (!isArrayType(maps[scopeFound], idx)) {
                          nonArrayError(typeFromIdx(maps[scopeFound], idx));
                        } else {
                          if (!isInRange(maps[scopeFound], idx, $3)) {
                            outOfBoundsError($1, arrBoundsAsString(maps[scopeFound], idx), $3);
                          }
                          if (!isInRange(maps[scopeFound], idx, $5)) {
                            outOfBoundsError($1, arrBoundsAsString(maps[scopeFound], idx), $5);
                          }
                          $$.type = typeFromStr(maps[scopeFound], $1); 
                          $$.lower = $3; $$.upper = $5;
                        }
                      }
                      free($1);
                     }
                   | IDENTIFIER { lists = addList(lists, ++listDepth); } '(' ArithExprList ')' {
                      int idx = lookupStringTable(maps[scope], $1);
                      $$.valKnown = 0;
                      if (idx == -1 && (scope != 1 || lookupStringTable(maps[0], $1) == -1)) {
                        undeclaredError($1);
                      } else {
                        int scopeFound = idx == -1 ? 0 : scope;
                        int expected = expectedNumArguments(maps[scopeFound], $1);
                        if (expected != lists[listDepth-1]->len) {
                          wrongNumArgumentsError($1, expected, lists[listDepth-1]->len);
                        } else {
                          idx = lookupStringTable(maps[scopeFound], $1);
                          for (int i = 0; i < expected; i++) {
                            int expectedType = maps[scopeFound]->symbols[idx].params[i].type;
                            int actualType = lists[listDepth-1]->items[i].type;
                            if (!isValidParamType(maps[scopeFound]->symbols[idx].params[i], lists[listDepth-1]->items[i])) {
                              if (typeGetsTruncated(maps[scopeFound]->symbols[idx].params[i], lists[listDepth-1]->items[i])) {
                                truncationError();
                              } else { wrongArgumentTypeError($1, i, expectedType, actualType); }
                            } else if (!isValidArraySlice(maps[scopeFound]->symbols[idx].params[i], lists[listDepth-1]->items[i])) {
                              Param e = maps[scopeFound]->symbols[idx].params[i];
                              ArithExprItem a = lists[listDepth-1]->items[i];
                              wrongRangeError($1, i, e.lower, e.upper, a.lower, a.upper);
                            }
                            int isRef = maps[scopeFound]->symbols[idx].params[i].ref;
                            if (isRef && (actualType == REALCON || actualType == INTCON)) { constAsRefError(); }
                            if (isRef && (actualType == FUNCI || actualType == FUNCR)) { funcAsRefError(); }
                          }
                        }
                        $$.type = typeFromStr(maps[scopeFound], $1);
                      }
                      lists = freeList(lists, --listDepth);
                      free($1);
                     }
                   | INTNUMBER   { $$.type = INTNUM;  $$.val = $1; $$.valKnown = 1; }
                   | REALNUMBER  { $$.type = REALNUM; $$.val = $1; $$.valKnown = 1; }
                   | ArithExpr '+' ArithExpr  {
                      if (!typeCanBeRhs($1.type)) {
                        noValueError($1.type);
                      }
                      if (!typeCanBeRhs($3.type)) {
                        noValueError($3.type);
                      }
                      $$.valKnown = 0; $$.type = isRealType($1.type) || isRealType($3.type) ? REALNUM : INTNUM;
                      if ($1.valKnown && $3.valKnown) {
                        $$.valKnown = 1; $$.val = $1.val + $3.val;
                      }
                     }
                   | ArithExpr '-' ArithExpr  {
                      if (!typeCanBeRhs($1.type)) {
                        noValueError($1.type);
                      }
                      if (!typeCanBeRhs($3.type)) {
                        noValueError($3.type);
                      }
                      $$.valKnown = 0; $$.type = isRealType($1.type) || isRealType($3.type) ? REALNUM : INTNUM;
                      if ($1.valKnown && $3.valKnown) {
                        $$.valKnown = 1; $$.val = $1.val - $3.val;
                      }
                     }
                   | ArithExpr '*' ArithExpr  {
                      if (!typeCanBeRhs($1.type)) {
                        noValueError($1.type);
                      }
                      if (!typeCanBeRhs($3.type)) {
                        noValueError($3.type);
                      }
                      $$.valKnown = 0; $$.type = isRealType($1.type) || isRealType($3.type) ? REALNUM : INTNUM;
                      if ($1.valKnown && $3.valKnown) {
                        $$.valKnown = 1; $$.val = $1.val * $3.val;
                      }
                     }
                   | ArithExpr '/' ArithExpr  {
                      if (!typeCanBeRhs($1.type)) {
                        noValueError($1.type);
                      } 
                      if (!typeCanBeRhs($3.type)) {
                        noValueError($3.type);
                      }
                      $$.valKnown = 0; $$.type = REALNUM;
                      if ($3.valKnown && $3.val == 0) {
                        divisionByZeroError();
                      } else if ($1.valKnown && $3.valKnown) {
                        $$.valKnown = 1;
                        $$.val = $1.val / $3.val;
                      }
                     }
                   | ArithExpr DIV ArithExpr  {
                      if (!typeCanBeRhs($1.type)) {
                        noValueError($1.type);
                      } else if (!isIntegerType($1.type)) {
                        divError($1.type);
                      }
                      if (!typeCanBeRhs($3.type)) {
                        noValueError($3.type);
                      } else if (!isIntegerType($3.type)) {
                        divError($3.type);
                      }
                      $$.valKnown = 0; $$.type = INTNUM;
                      if (isIntegerType($1.type) && isIntegerType($3.type)) {
                        if ($3.valKnown && $3.val == 0) {
                          divisionByZeroError();
                        } else if ($1.valKnown && $3.valKnown) {
                          $$.valKnown = 1;
                          $$.val = $1.val / $3.val;
                        }
                      }
                     }
                   | ArithExpr MOD ArithExpr  {  // Only defined for integer types
                      if (!typeCanBeRhs($1.type)) {
                        noValueError($1.type);
                      } else if (!isIntegerType($1.type)) {
                        moduloError($1.type);
                      }
                      if (!typeCanBeRhs($3.type)) {
                        noValueError($3.type);
                      } else if (!isIntegerType($3.type)) {
                        moduloError($3.type);
                      }
                      $$.valKnown = 0; $$.type = INTNUM;
                      if (isIntegerType($1.type) && isIntegerType($3.type)) {
                        if ($3.valKnown && $3.val == 0) {
                          modByZeroError();
                        } else if ($1.valKnown && $3.valKnown) {
                          $$.valKnown = 1;
                          $$.val = (int)$1.val % (int)$3.val;
                        }
                      }
                     }
                   | '-' ArithExpr { 
                      $$.type = $2.type; $$.valKnown = 0;
                      if (!typeCanBeRhs($2.type)) {
                        noValueError($2.type);
                      } else if ($2.valKnown) { 
                        $$.val = -$2.val; $$.valKnown = 1; 
                      }
                     }
                   | '(' ArithExpr ')' { 
                      $$.type = $2.type; $$.valKnown = 0;
                      if (!typeCanBeRhs($2.type)) {
                        noValueError($2.type);
                      } else if ($2.valKnown) { 
                        $$.val = $2.val; $$.valKnown = 1; 
                      }
                     }
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
  freeStringTable(maps[0]);
  if (maps[1]) {
    freeStringTable(maps[1]);
  }
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

  maps[0] = newStringTable();
  maps[1] = NULL;
  initLexer(input);
  int result = yyparse();
  finalizeLexer();

#if 0
  showStringTable(maps[0]);
#endif

  printf("ERRORS: %d\n", ERRORS);
  puts(ERRORS == 0 ? "ACCEPTED" : "REJECTED");

  fclose(input);

  freeStringTable(maps[0]);
  if (maps[1]) {
    freeStringTable(maps[1]);
  }
  free(lists);

  return EXIT_SUCCESS;
}
