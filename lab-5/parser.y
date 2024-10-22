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

  FILE *output;
  int indentLevel = 0;

  ArithExprList **lists = NULL;
  int listDepth = 0;

  int buffI = 0;
  int buffBI = 0;
  int buffMax = 1024;
  char buff[1024];
  char buffB[1024];
  int paramsCount = 0;
  int params[100];

  int lab = 0;
  int tempVarCounter = 0;

  int readln = 0;

  int scope = 0;             // 0 = in global scope, 1 = in local scope
  HashMap *maps[2];          // maps[0] is the global scope, maps[1] is the local scope
  char *currentFunc = NULL;  // If declaring a function set the name for easy access

  void *indent() {
    for (int i = 0; i < indentLevel*2; i++) {
      fprintf(output, " ");
    }
  }

  void *indentBuff() {
    for (int i = 0; i < indentLevel*2; i++) {
      snprintf(buff + buffI + i, buffMax - buffI - i, " ");
    }
    buffI += (2 * indentLevel);
  }
%}

%union {
  int ival;     /* used for passing int values from lexer to parser    */
  double dval;  /* used for passing double values from lexer to parser */
  char* id;     /* used for passing char* values from lexer to parser  */
  struct {
    double val;
    int type;
  } numeric;
  struct {
    int type;
    int array;
    int lower;
    int upper;
  } typeSpec;
  struct {
    double val;
    int type;
    int lower;
    int upper;
    int t;
  } expr;
  int type;
  int t;
}

%token PROGRAM CONST VAR ARRAY RANGE OF
       FUNCTION PROCEDURE BEGINTOK ENDTOK ASSIGN IF THEN ELSE WHILE DO
       RELOPLT RELOPLEQ RELOPEQ RELOPNEQ RELOPGEQ RELOPGT INTEGER REAL
       AND OR NOT DIV MOD SKIP READLN WRITELN

%token <id>   IDENTIFIER
%token <ival> INTNUMBER
%token <dval> REALNUMBER

%type <numeric>    NumericValue
%type <type>       BasicType
%type <typeSpec>   TypeSpec
%type <id>         IdentifierList Relop
%type <expr>       Lhs ArithExpr
%type <t>          BoolAtom Guard

%left '+' '-'
%left '*' '/' DIV MOD
%left OR
%left AND
%left NOT

%%

program            : PROGRAM IDENTIFIER { fprintf(output, "#include <stdio.h>\n#include <stdlib.h>\n"); free($2); } ';'
                     ConstDecl
                     VarDecl
                     FuncProcDecl      { fprintf(output, "int main() {\n"); indentLevel++; tempVarCounter = 0; }
                     CompoundStatement { fprintf(output, "  return 0;\n}\n"); }
                     '.'
                   ;

ConstDecl          : ConstDecl CONST IDENTIFIER RELOPEQ NumericValue ';' {
                      int idx = insertOrRetrieveStringTable(maps[scope], $3);
                      setType(maps[scope], idx, $5.type); setVal(maps[scope], idx, $5.val);
                      if ($5.type == INTCON) {
                        fprintf(output, "const int %s = %d;\n", $3, (int)$5.val);
                      } else {
                        fprintf(output, "const double %s = %lf;\n", $3, $5.val);
                      }
                      free($3);
                     }
                   | %empty { fprintf(output, "\n"); }
                   ;

NumericValue       : INTNUMBER   { $$.val = $1; $$.type = INTCON;  }
                   | REALNUMBER  { $$.val = $1; $$.type = REALCON; }
                   ;

VarDecl            : VarDecl VAR IdentifierList ':' TypeSpec ';' {
                      HashMap *map = maps[scope]; char *type = $5.type == INTNUM ? "int" : "double";
                      if ($5.array) {
                        for (int i = 0; i < map->capacity; i++) {
                          if (map->symbols[i].str && map->symbols[i].type == NONE) {
                            indent(); int n = $5.upper - $5.lower + 1;
                            //fprintf(output, "%s *%s = calloc(%d, sizeof(%s));\n", type, map->symbols[i].str, n, type);
                            fprintf(output, "%s %s[%d];\n", type, map->symbols[i].str, n);
                          }
                        }
                        assignArrayTypes(map, $5.type, $5.lower, $5.upper);
                      } else {
                        for (int i = 0; i < map->capacity; i++) {
                          if (map->symbols[i].str && map->symbols[i].type == NONE) {
                            indent();
                            fprintf(output, "%s %s;\n", type, map->symbols[i].str);
                          }
                        }
                        assignTypes(map, $5.type, 0);
                      }
                      paramsCount = 0;
                     }
                   | %empty { fprintf(output, "\n"); }
                   ;

IdentifierList     : IDENTIFIER { params[paramsCount++] = insertOrRetrieveStringTable(maps[scope], $1); free($1); }
                   | IdentifierList ',' IDENTIFIER { params[paramsCount++] = insertOrRetrieveStringTable(maps[scope], $3); free($3); }
                   ;

TypeSpec           : BasicType                                            { $$.type = $1; $$.array = 0; }
                   | ARRAY '[' INTNUMBER RANGE INTNUMBER ']' OF BasicType { $$.type = $8; $$.array = 1; $$.lower = $3; $$.upper = $5; }
                   ;

BasicType          : INTEGER  { $$ = INTNUM;  }
                   | REAL     { $$ = REALNUM; }
                   ;

FuncProcDecl       : FuncProcDecl SubProgDecl ';'
                   | %empty { fprintf(output, "\n"); }
                   ;

SubProgDecl        : { maps[++scope] = newStringTable(); } SubProgHeading { paramsCount = 0; indentLevel++; tempVarCounter = 0; } VarDecl CompoundStatement {
                      if (currentFunc) { fprintf(output, "  return %s;\n}\n\n", currentFunc); free(currentFunc); currentFunc = NULL; }
                      else             { fprintf(output, "}\n\n"); }
                      freeStringTable(maps[scope]); maps[scope--] = NULL; indentLevel--;
                     }
                   ;

SubProgHeading     : FUNCTION IDENTIFIER { currentFunc = $2; insertOrRetrieveStringTable(maps[0], currentFunc); }
                     Parameters ':' BasicType ';' {
                      setType(maps[0], lookupStringTable(maps[0], currentFunc), ($6 == INTNUM ? FUNCI : FUNCR));
                      copyToLocalScope(maps[0], maps[1], currentFunc); buffI = 0;
                      fprintf(output, "%s f_%s(%s) {\n  %s %s;", $6 == INTNUM ? "int" : "double", currentFunc, buff, $6 == INTNUM ? "int" : "double", currentFunc);
                     }
                   | PROCEDURE IDENTIFIER { currentFunc = $2; buff[0] = '\0';
                      int idx = insertOrRetrieveStringTable(maps[0], currentFunc); setType(maps[0], idx, PROC);
                     } PossibleParameters ';' { fprintf(output, "void f_%s(%s) {", currentFunc, buff);
                      free(currentFunc); currentFunc = NULL; buffI = 0;
                     }
                   ;

PossibleParameters : Parameters
                   | %empty
                   ;

Parameters         : '(' ParameterList ')'
                   ;

ParameterList      : ParamList { paramsCount = 0; }
                   | ParameterList ';' ParamList { paramsCount = 0; }
                   ;

ParamList          : VAR IdentifierList ':' TypeSpec {
                      int count = 0; int type = $4.type;
                      if ($4.array) {
                        count = assignArrayTypes(maps[scope], $4.type, $4.lower, $4.upper);
                        type = $4.type == REALNUM ? ARROR : ARROI;
                      } else {
                        count = assignTypes(maps[scope], $4.type, 1);
                      }
                      char *t = $4.type == INTNUM ? "int *" : "double *";
                      if (buffI == 0) {
                        snprintf(buff, buffMax, "%s%s", t, maps[scope]->symbols[params[0]].str);
                        buffI = strlen(buff);
                        for (int i = 1; i < paramsCount; i++) {
                          snprintf(buff + buffI, buffMax - buffI, ", %s%s", t, maps[scope]->symbols[params[i]].str);
                          buffI = strlen(buff);
                        }
                      } else {
                        for (int i = 0; i < paramsCount; i++) {
                          snprintf(buff + buffI, buffMax - buffI, ", %s%s", t, maps[scope]->symbols[params[i]].str);
                          buffI = strlen(buff);
                        }
                      }
                      addParams(maps[0], currentFunc, count, type, $4.lower, $4.upper, 1);
                     }
                   | IdentifierList ':' TypeSpec {
                      int count = 0; int type = $3.type;
                      char *t = NULL;
                      if ($3.array) {
                        count = assignArrayTypes(maps[scope], $3.type, $3.lower, $3.upper);
                        type = $3.type == REALNUM ? ARROR : ARROI;
                        t = $3.type == REALNUM ? "double *" : "int *";
                      } else {
                        count = assignTypes(maps[scope], $3.type, 0);
                        t = $3.type == REALNUM ? "double " : "int ";
                      }
                      if (buffI == 0) {
                        snprintf(buff, buffMax, "%s%s", t, maps[scope]->symbols[params[0]].str);
                        buffI = strlen(buff);
                        for (int i = 1; i < paramsCount; i++) {
                          snprintf(buff + buffI, buffMax - buffI, ", %s%s", t, maps[scope]->symbols[params[i]].str);
                          buffI = strlen(buff);
                        }
                      } else {
                        for (int i = 0; i < paramsCount; i++) {
                          snprintf(buff + buffI, buffMax - buffI, ", %s%s", t, maps[scope]->symbols[params[i]].str);
                          buffI = strlen(buff);
                        }
                      }
                      addParams(maps[0], currentFunc, count, type, $3.lower, $3.upper, 0);
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

Statement          : Lhs ASSIGN ArithExpr { fprintf(output, "%s = _t%d;\n", buff, tempVarCounter - 1); buffI = 0; }
                   | SKIP
                   | ProcedureCall
                   | CompoundStatement
                   | IF Guard {
                      params[paramsCount++] = lab;
                      int lab1 = lab; 
                      lab += 2;
                      fprintf(output, "if (!_t%d) goto lb%d;\n", tempVarCounter - 1, lab1);
                     } THEN Statement { 
                      int lab1 = params[paramsCount - 1]; 
                      fprintf(output, "goto lb%d;\n", lab1 + 1);
                      fprintf(output, "lb%d : ;\n", lab1);
                     } ELSE Statement {
                      int lab1 = params[--paramsCount]; 
                      fprintf(output, "lb%d : ;\n", lab1+1);
                     }
                   | WHILE {
                      params[paramsCount++] = lab;
                      int lab1 = lab;
                      lab += 2;
                      fprintf(output, "lb%d : ;\n", lab1);
                     } Guard {
                      int lab1 = params[paramsCount-1]; 
                      fprintf(output, "if (!_t%d) goto lb%d;\n", tempVarCounter - 1, lab1 + 1);
                     } DO Statement { 
                      int lab1 = params[--paramsCount]; 
                      fprintf(output, "goto lb%d;\n", lab1); 
                      fprintf(output, "lb%d : ;\n", lab1 + 1); 
                     }
                   ;

LhsList            : Lhs
                   | LhsList ',' { 
                      snprintf(buffB + buffBI, buffMax - buffBI, " "); buffBI = strlen(buffB); 
                      snprintf(buff + buffI, buffMax - buffI, ", "); buffI = strlen(buff); 
                     } Lhs

Lhs                : IDENTIFIER {
                      int idx = lookupStringTable(maps[scope], $1);
                      int scopeFound = idx == -1 ? 0 : scope;
                      idx = lookupStringTable(maps[scopeFound], $1);
                      $$.type = typeFromIdx(maps[scopeFound], idx);
                      char *t = isIntegerType($$.type) ? "%d" : "%lf";
                      if (readln) {
                        if (maps[scopeFound]->symbols[idx].isRef) {
                          snprintf(buff + buffI, buffMax - buffI, "%s", $1);
                          snprintf(buffB + buffBI, buffMax - buffBI, "%s", t);
                        } else {
                          snprintf(buff + buffI, buffMax - buffI, "&%s", $1);
                          snprintf(buffB + buffBI, buffMax - buffBI, "%s", t);
                        }
                      } else {
                        indentBuff();
                        if (maps[scopeFound]->symbols[idx].isRef) {
                          snprintf(buff + buffI, buffMax - buffI, "*%s", $1);
                        } else {
                          snprintf(buff + buffI, buffMax - buffI, "%s", $1);
                        }
                      }
                      buffI = strlen(buff);
                      buffBI = strlen(buffB);
                      free($1);
                     }
                   | IDENTIFIER '[' ArithExpr ']' {
                      int idx = lookupStringTable(maps[scope], $1);
                      int scopeFound = idx == -1 ? 0 : scope;
                      idx = lookupStringTable(maps[scopeFound], $1);
                      $$.type = typeFromArr(typeFromStr(maps[scopeFound], $1));
                      char *t = isIntegerType($$.type) ? "%d" : "%lf";
                      int lower = maps[scopeFound]->symbols[idx].lower;
                      if (readln) {
                        if (maps[scopeFound]->symbols[idx].isRef) {
                          fprintf(output, "_t%d = _t%d - %d;\n", $3.t, $3.t, lower);
                          snprintf(buff + buffI, buffMax - buffI, "&%s[_t%d]", $1, $3.t);
                          buffI = strlen(buff);
                          snprintf(buffB + buffBI, buffMax - buffBI, "%s", t);
                        } else {
                          fprintf(output, "_t%d = _t%d - %d;\n", $3.t, $3.t, lower);
                          snprintf(buff + buffI, buffMax - buffI, "&%s[_t%d]", $1, $3.t);
                          buffI = strlen(buff);
                          snprintf(buffB + buffBI, buffMax - buffBI, "%s", t);
                        }
                      } else {
                        indentBuff();
                        if (maps[scopeFound]->symbols[idx].isRef) {
                          snprintf(buff + buffI, buffMax - buffI, "*%s", $1);
                        } else {
                          snprintf(buff + buffI, buffMax - buffI, "_t%d = _t%d - %d;\n", $3.t, $3.t, maps[scopeFound]->symbols[idx].lower);
                          buffI = strlen(buff);
                          snprintf(buff + buffI, buffMax - buffI, "%s[_t%d]", $1, $3.t);
                        }
                      }
                      buffI = strlen(buff);
                      buffBI = strlen(buffB);
                      free($1);
                     }
                   ;

ProcedureCall      : IDENTIFIER {
                      int idx = lookupStringTable(maps[0], $1);
                      indent(); fprintf(output, "f_%s();\n", $1);
                      free($1);
                     }
                   | IDENTIFIER { lists = addList(lists, ++listDepth); } '(' ArithExprList ')' {
                      int idx = lookupStringTable(maps[0], $1);
                      int expected = expectedNumArguments(maps[0], $1);
                      for (int i = 0; i < expected; i++) {
                        int expectedType = maps[0]->symbols[idx].params[i].type;
                        int actualType = lists[listDepth-1]->items[i].type;
                      }
                      lists = freeList(lists, --listDepth);
                      //indent(); fprintf(output, "%s(%s);\n", $1, buff, );
                      free($1);
                     }
                   | READLN { readln = 1; buffBI = 0; indent(); } '(' LhsList ')' { fprintf(output, "scanf(\"%s\", %s);\n", buffB, buff); readln = 0; buffI = 0; buffBI = 0;}
                   | WRITELN { lists = addList(lists, ++listDepth); } '(' ArithExprList ')' {
                      int len = lists[listDepth-1]->len;
                      for (int i = 0; i < len; i++) {
                        //int type = lists[listDepth-1]->items[i].type;
                        fprintf(output, "%s", lists[listDepth-1]->buffs[i].buff);
                      }
                      fprintf(output, "printf(\"");
                      int type = lists[listDepth-1]->items[0].type;
                      fprintf(output, "%%%s", isIntegerType(type) ? "d" : "lf");
                      for (int i = 1; i < len; i++) {
                        type = lists[listDepth-1]->items[i].type;
                        fprintf(output, " %%%s", isIntegerType(type) ? "d" : "lf");
                      }
                      fprintf(output, "\\n\"");
                      for (int i = 0; i < len; i++) {
                        fprintf(output, ", %s", lists[listDepth-1]->buffs[i].raw);
                      }
                      fprintf(output, ");\n");
                      lists = freeList(lists, --listDepth);
                     }
                   ;

Guard              : BoolAtom         { $$ = $1; }
                   | NOT Guard        { $$ = tempVarCounter; fprintf(output, "int _t%d = !_t%d;\n", tempVarCounter++, $2); }
                   | Guard OR Guard   { $$ = tempVarCounter; fprintf(output, "int _t%d = _t%d || _t%d;\n", tempVarCounter++, $1, $3); }
                   | Guard AND Guard  { $$ = tempVarCounter; fprintf(output, "int _t%d = _t%d && _t%d;\n", tempVarCounter++, $1, $3); }
                   | '(' Guard ')'    { $$ = $2; }
                   ;

BoolAtom           : ArithExpr Relop ArithExpr  { $$ = tempVarCounter; fprintf(output, "int _t%d = _t%d %s _t%d;\n", tempVarCounter++, $1.t, $2, $3.t); }
                   ;

Relop              : RELOPLT   { $$ =  "<"; }
                   | RELOPLEQ  { $$ = "<="; }
                   | RELOPEQ   { $$ = "=="; }
                   | RELOPNEQ  { $$ = "!="; }
                   | RELOPGEQ  { $$ = ">="; }
                   | RELOPGT   { $$ =  ">"; }
                   ;

ArithExprList      : ArithExpr                    { addArithExpr(lists, listDepth-1, $1.type, $1.val, $1.lower, $1.upper); }
                   | ArithExprList ',' ArithExpr  { addArithExpr(lists, listDepth-1, $3.type, $3.val, $3.lower, $3.upper); }
                   ;

ArithExpr          : IDENTIFIER {
                      $$.t = tempVarCounter;
                      int idx = lookupStringTable(maps[scope], $1);
                      int scopeFound = idx == -1 ? 0 : scope;
                      idx = lookupStringTable(maps[scopeFound], $1);
                      char *t = isIntegerType(typeFromIdx(maps[scopeFound], idx)) ? "int " : "double ";
                      if (listDepth == 0) {
                        indent(); fprintf(output, "%s_t%d = %s;\n", t, tempVarCounter++, $1);
                      } else {
                        int i = lists[listDepth-1]->len;
                        snprintf(lists[listDepth-1]->buffs[i].buff + lists[listDepth-1]->buffs[i].buffI, buffMax - lists[listDepth-1]->buffs[i].buffI, "%s_t%d = %s;\n", t, tempVarCounter, $1);
                        lists[listDepth-1]->buffs[i].buffI = strlen(lists[listDepth-1]->buffs[i].buff);
                        snprintf(lists[listDepth-1]->buffs[i].raw, buffMax, "_t%d", tempVarCounter);
                        snprintf(lists[listDepth-1]->buffs[i].asRef, buffMax, "%s", $1); tempVarCounter++;
                      }
                      $$.type = typeFromIdx(maps[scopeFound], idx);
                      free($1);
                     }
                   | IDENTIFIER '[' ArithExpr ']' {
                      $$.t = tempVarCounter;
                      int idx = lookupStringTable(maps[scope], $1);
                      int scopeFound = idx == -1 ? 0 : scope;
                      idx = lookupStringTable(maps[scopeFound], $1);
                      char *t = typeFromIdx(maps[scopeFound], idx) == ARROI ? "int " : "double ";
                      int lower = maps[scopeFound]->symbols[idx].lower;
                      if (listDepth == 0) {
                        indent(); 
                        fprintf(output, "_t%d = _t%d - %d;\n", $3.t, $3.t, lower);
                        fprintf(output, "%s_t%d = %s[_t%d];\n", t, tempVarCounter++, $1, $3.t);
                      } else {
                        int i = lists[listDepth-1]->len;
                        snprintf(lists[listDepth-1]->buffs[i].buff + lists[listDepth-1]->buffs[i].buffI, buffMax - lists[listDepth-1]->buffs[i].buffI, "_t%d = _t%d - %d;\n", $3.t, $3.t, lower);
                        lists[listDepth-1]->buffs[i].buffI = strlen(lists[listDepth-1]->buffs[i].buff);
                        snprintf(lists[listDepth-1]->buffs[i].buff + lists[listDepth-1]->buffs[i].buffI, buffMax - lists[listDepth-1]->buffs[i].buffI, "%s_t%d = %s[_t%d];\n", t, tempVarCounter, $1, $3.t);
                        lists[listDepth-1]->buffs[i].buffI = strlen(lists[listDepth-1]->buffs[i].buff);
                        snprintf(lists[listDepth-1]->buffs[i].raw, buffMax, "_t%d", tempVarCounter);
                        snprintf(lists[listDepth-1]->buffs[i].asRef, buffMax, "%s", $1); tempVarCounter++;
                      }
                      $$.type = typeFromArr(typeFromIdx(maps[scopeFound], idx));
                      free($1);
                     }
                   | IDENTIFIER '[' INTNUMBER RANGE INTNUMBER ']' {
                      $$.t = tempVarCounter;
                      int idx = lookupStringTable(maps[scope], $1);
                      int scopeFound = idx == -1 ? 0 : scope;
                      idx = lookupStringTable(maps[scopeFound], $1);
                      $$.type = typeFromStr(maps[scopeFound], $1);
                      //$$.lower = $3; $$.upper = $5;
                      free($1);
                     }
                   | IDENTIFIER { lists = addList(lists, ++listDepth); } '(' ArithExprList ')' {
                      $$.t = tempVarCounter;
                      int idx = lookupStringTable(maps[0], $1);
                      int expected = expectedNumArguments(maps[0], $1);
                      char *t = isIntegerType(typeFromIdx(maps[0], idx)) ? "int " : "double ";
                      if (listDepth > 1) {
                        int j = lists[listDepth-2]->len;
                        for (int i = 0; i < expected; i++) {
                          int expectedType = maps[0]->symbols[idx].params[i].type;
                          int actualType = lists[listDepth-1]->items[i].type;
                          if (!maps[0]->symbols[idx].params[i].ref) {
                            snprintf(lists[listDepth-2]->buffs[j].buff + lists[listDepth-2]->buffs[j].buffI, buffMax - lists[listDepth-2]->buffs[j].buffI,  "%s", lists[listDepth-1]->buffs[i].buff);
                            lists[listDepth-2]->buffs[j].buffI = strlen(lists[listDepth-2]->buffs[j].buff);
                          }
                        }
                        snprintf(lists[listDepth-2]->buffs[j].buff + lists[listDepth-2]->buffs[j].buffI, buffMax - lists[listDepth-2]->buffs[j].buffI, "%s_t%d = f_%s(", t, tempVarCounter++, $1);
                        lists[listDepth-2]->buffs[j].buffI = strlen(lists[listDepth-2]->buffs[j].buff);
                        if (maps[0]->symbols[idx].params[0].ref) {
                          snprintf(lists[listDepth-2]->buffs[j].buff + lists[listDepth-2]->buffs[j].buffI, buffMax - lists[listDepth-2]->buffs[j].buffI,  "&%s", lists[listDepth-1]->buffs[0].raw);
                          lists[listDepth-2]->buffs[j].buffI = strlen(lists[listDepth-2]->buffs[j].buff);
                        } else {
                          snprintf(lists[listDepth-2]->buffs[j].buff + lists[listDepth-2]->buffs[j].buffI, buffMax - lists[listDepth-2]->buffs[j].buffI,  "%s", lists[listDepth-1]->buffs[0].raw);
                          lists[listDepth-2]->buffs[j].buffI = strlen(lists[listDepth-2]->buffs[j].buff);
                        }
                        for (int i = 1; i < expected; i++) {
                          int expectedType = maps[0]->symbols[idx].params[i].type;
                          int actualType = lists[listDepth-1]->items[i].type;
                          if (maps[0]->symbols[idx].params[i].ref) {
                            snprintf(lists[listDepth-2]->buffs[j].buff + lists[listDepth-2]->buffs[j].buffI, buffMax - lists[listDepth-2]->buffs[j].buffI,  ", &%s", lists[listDepth-1]->buffs[i].raw);
                            lists[listDepth-2]->buffs[j].buffI = strlen(lists[listDepth-2]->buffs[j].buff);
                          } else {
                            snprintf(lists[listDepth-2]->buffs[j].buff + lists[listDepth-2]->buffs[j].buffI, buffMax - lists[listDepth-2]->buffs[j].buffI,  ", %s", lists[listDepth-1]->buffs[i].raw);
                            lists[listDepth-2]->buffs[j].buffI = strlen(lists[listDepth-2]->buffs[j].buff);
                          }
                        }
                        snprintf(lists[listDepth-2]->buffs[j].buff + lists[listDepth-2]->buffs[j].buffI, buffMax - lists[listDepth-2]->buffs[j].buffI,  ");\n");
                        lists[listDepth-2]->buffs[j].buffI = strlen(lists[listDepth-2]->buffs[j].buff);
                        snprintf(lists[listDepth-2]->buffs[j].raw, buffMax,  "_t%d", tempVarCounter-1);
                      } else {
                        for (int i = 0; i < expected; i++) {
                          int expectedType = maps[0]->symbols[idx].params[i].type;
                          int actualType = lists[listDepth-1]->items[i].type;
                          if (!maps[0]->symbols[idx].params[i].ref) {
                            fprintf(output, "%s", lists[listDepth-1]->buffs[i].buff);
                          }
                        }
                        fprintf(output, "%s_t%d = f_%s(", t, tempVarCounter++, $1);
                        if (maps[0]->symbols[idx].params[0].ref) {
                          fprintf(output, "&%s", lists[listDepth-1]->buffs[0].raw);
                        } else {
                          fprintf(output, "%s", lists[listDepth-1]->buffs[0].raw);
                        }
                        for (int i = 1; i < expected; i++) {
                          int expectedType = maps[0]->symbols[idx].params[i].type;
                          int actualType = lists[listDepth-1]->items[i].type;
                          if (maps[0]->symbols[idx].params[i].ref) {
                            fprintf(output, ", &%s", lists[listDepth-1]->buffs[i].raw);
                          } else {
                            fprintf(output, ", %s", lists[listDepth-1]->buffs[i].raw);
                          }
                        }
                        fprintf(output, ");\n");
                      }
                      $$.type = typeFromStr(maps[0], $1);
                      lists = freeList(lists, --listDepth);
                      free($1);
                     }
                   | INTNUMBER { $$.t = tempVarCounter; $$.type = INTNUM;
                      if (listDepth == 0) {
                        indent(); fprintf(output, "int _t%d = %d;\n", tempVarCounter++, $1);
                      } else {
                        int i = lists[listDepth-1]->len;
                        snprintf(lists[listDepth-1]->buffs[i].buff + lists[listDepth-1]->buffs[i].buffI, buffMax - lists[listDepth-1]->buffs[i].buffI, "int _t%d = %d;\n", tempVarCounter, $1);
                        lists[listDepth-1]->buffs[i].buffI = strlen(lists[listDepth-1]->buffs[i].buff);
                        snprintf(lists[listDepth-1]->buffs[i].raw, buffMax, "_t%d", tempVarCounter); tempVarCounter++;
                      }
                     }
                   | REALNUMBER { $$.t = tempVarCounter; $$.type = REALNUM;
                      if (listDepth == 0) {
                        indent(); fprintf(output, "double _t%d = %lf;\n", tempVarCounter++, $1);
                      } else {
                        int i = lists[listDepth-1]->len;
                        snprintf(lists[listDepth-1]->buffs[i].buff + lists[listDepth-1]->buffs[i].buffI, buffMax - lists[listDepth-1]->buffs[i].buffI, "double _t%d = _t%lf;\n", tempVarCounter, $1);
                        lists[listDepth-1]->buffs[i].buffI = strlen(lists[listDepth-1]->buffs[i].buff);
                        snprintf(lists[listDepth-1]->buffs[i].raw, buffMax, "_t%d", tempVarCounter); tempVarCounter++;
                      }
                     }
                   | ArithExpr '+' ArithExpr {
                      $$.t = tempVarCounter; $$.type = isRealType($1.type) || isRealType($3.type) ? REALNUM : INTNUM; char *t = $$.type == REALNUM ? "double" : "int";
                      if (listDepth == 0) {
                        indent(); fprintf(output, "%s _t%d = _t%d + _t%d;\n", t, tempVarCounter, $1.t, $3.t); tempVarCounter++;
                      } else {
                        int i = lists[listDepth-1]->len;
                        snprintf(lists[listDepth-1]->buffs[i].buff + lists[listDepth-1]->buffs[i].buffI, buffMax - lists[listDepth-1]->buffs[i].buffI, "%s _t%d = _t%d + _t%d;\n", t, tempVarCounter, $1.t, $3.t);
                        lists[listDepth-1]->buffs[i].buffI = strlen(lists[listDepth-1]->buffs[i].buff);
                        snprintf(lists[listDepth-1]->buffs[i].raw, buffMax, "_t%d", tempVarCounter); tempVarCounter++;
                      }
                     }
                   | ArithExpr '-' ArithExpr {
                      $$.t = tempVarCounter; $$.type = isRealType($1.type) || isRealType($3.type) ? REALNUM : INTNUM; char *t = $$.type == REALNUM ? "double" : "int";
                      if (listDepth == 0) {
                        indent(); fprintf(output, "%s _t%d = _t%d - _t%d;\n", t, tempVarCounter, $1.t, $3.t); tempVarCounter++;
                      } else {
                        int i = lists[listDepth-1]->len;
                        snprintf(lists[listDepth-1]->buffs[i].buff + lists[listDepth-1]->buffs[i].buffI, buffMax - lists[listDepth-1]->buffs[i].buffI, "%s _t%d = _t%d - _t%d;\n", t, tempVarCounter, $1.t, $3.t);
                        lists[listDepth-1]->buffs[i].buffI = strlen(lists[listDepth-1]->buffs[i].buff);
                        snprintf(lists[listDepth-1]->buffs[i].raw, buffMax, "_t%d", tempVarCounter); tempVarCounter++;
                      }
                     }
                   | ArithExpr '*' ArithExpr {
                      $$.t = tempVarCounter; $$.type = isRealType($1.type) || isRealType($3.type) ? REALNUM : INTNUM; char *t = $$.type == REALNUM ? "double" : "int";
                      if (listDepth == 0) {
                        indent(); fprintf(output, "%s _t%d = _t%d * _t%d;\n", t, tempVarCounter, $1.t, $3.t); tempVarCounter++;
                      } else {
                        int i = lists[listDepth-1]->len;
                        snprintf(lists[listDepth-1]->buffs[i].buff + lists[listDepth-1]->buffs[i].buffI, buffMax - lists[listDepth-1]->buffs[i].buffI, "%s _t%d = _t%d * _t%d;\n", t, tempVarCounter, $1.t, $3.t);
                        lists[listDepth-1]->buffs[i].buffI = strlen(lists[listDepth-1]->buffs[i].buff);
                        snprintf(lists[listDepth-1]->buffs[i].raw, buffMax, "_t%d", tempVarCounter); tempVarCounter++;
                      }
                     }
                   | ArithExpr '/' ArithExpr {
                      $$.t = tempVarCounter; $$.type = REALNUM;
                      if (listDepth == 0) {
                        indent(); fprintf(output, "double _t%d = (double)_t%d / (double)_t%d;\n", tempVarCounter, $1.t, $3.t); tempVarCounter++;
                      } else {
                        int i = lists[listDepth-1]->len;
                        snprintf(lists[listDepth-1]->buffs[i].buff + lists[listDepth-1]->buffs[i].buffI, buffMax - lists[listDepth-1]->buffs[i].buffI, "double _t%d = (double)_t%d / (double)_t%d;\n", tempVarCounter, $1.t, $3.t);
                        lists[listDepth-1]->buffs[i].buffI = strlen(lists[listDepth-1]->buffs[i].buff);
                        snprintf(lists[listDepth-1]->buffs[i].raw, buffMax, "_t%d", tempVarCounter); tempVarCounter++;
                      }
                     }
                   | ArithExpr DIV ArithExpr {
                      $$.t = tempVarCounter; $$.type = INTNUM;
                      if (listDepth == 0) {
                        indent(); fprintf(output, "int _t%d = (int)_t%d / (int)_t%d;\n", tempVarCounter, $1.t, $3.t); tempVarCounter++;
                      } else {
                        int i = lists[listDepth-1]->len;
                        snprintf(lists[listDepth-1]->buffs[i].buff + lists[listDepth-1]->buffs[i].buffI, buffMax - lists[listDepth-1]->buffs[i].buffI, "int _t%d = (int)_t%d / (int)_t%d;\n", tempVarCounter, $1.t, $3.t);
                        lists[listDepth-1]->buffs[i].buffI = strlen(lists[listDepth-1]->buffs[i].buff);
                        snprintf(lists[listDepth-1]->buffs[i].raw, buffMax, "_t%d", tempVarCounter); tempVarCounter++;
                      }
                     }
                   | ArithExpr MOD ArithExpr {
                      $$.t = tempVarCounter; $$.type = INTNUM;
                      if (listDepth == 0) {
                        indent(); fprintf(output, "int _t%d = (int)_t%d %% (int)_t%d;\n", tempVarCounter, $1.t, $3.t); tempVarCounter++;
                      } else {
                        int i = lists[listDepth-1]->len;
                        snprintf(lists[listDepth-1]->buffs[i].buff + lists[listDepth-1]->buffs[i].buffI, buffMax - lists[listDepth-1]->buffs[i].buffI, "int _t%d = (int)_t%d %% (int)_t%d;\n", tempVarCounter, $1.t, $3.t);
                        lists[listDepth-1]->buffs[i].buffI = strlen(lists[listDepth-1]->buffs[i].buff);
                        snprintf(lists[listDepth-1]->buffs[i].raw, buffMax, "_t%d", tempVarCounter); tempVarCounter++;
                      }
                     }
                   | '-' ArithExpr {
                      $$.t = tempVarCounter; $$.type = $2.type; char *t = $$.type == REALNUM ? "double" : "int";
                      if (listDepth == 0) {
                        indent(); fprintf(output, "%s _t%d = -_t%d;\n", t, tempVarCounter, $2.t); tempVarCounter++;
                      } else {
                        int i = lists[listDepth-1]->len;
                        snprintf(lists[listDepth-1]->buffs[i].buff + lists[listDepth-1]->buffs[i].buffI, buffMax - lists[listDepth-1]->buffs[i].buffI, "%s _t%d = -1 * _t%d;\n", t, tempVarCounter, $2.t);
                        lists[listDepth-1]->buffs[i].buffI = strlen(lists[listDepth-1]->buffs[i].buff);
                        snprintf(lists[listDepth-1]->buffs[i].raw, buffMax, "_t%d", tempVarCounter); tempVarCounter++;
                      }
                     }
                   | '(' ArithExpr ')' {
                      $$.t = tempVarCounter; $$.type = $2.type; char *t = $$.type == REALNUM ? "double" : "int";
                      if (listDepth == 0) {
                        indent(); fprintf(output, "%s _t%d = _t%d;\n", t, tempVarCounter, $2.t); tempVarCounter++;
                      } else {
                        int i = lists[listDepth-1]->len;
                        snprintf(lists[listDepth-1]->buffs[i].buff + lists[listDepth-1]->buffs[i].buffI, buffMax - lists[listDepth-1]->buffs[i].buffI, "%s _t%d = _t%d;\n", t, tempVarCounter, $2.t);
                        lists[listDepth-1]->buffs[i].buffI = strlen(lists[listDepth-1]->buffs[i].buff);
                        snprintf(lists[listDepth-1]->buffs[i].raw, buffMax, "_t%d", tempVarCounter); tempVarCounter++;
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
  if (argc != 3) {
    fprintf(stderr, "Usage: %s [pasfile] [outfile]\n", argv[0]);
    return EXIT_FAILURE;
  }

  FILE *input  = (strcmp(argv[1], "-") == 0) ? stdin  : fopen(argv[1], "r");
  if(input == NULL) {
    fprintf(stderr, "Failed to open input file!\n");
    exit(EXIT_FAILURE);
  }

  output = (strcmp(argv[2], "-") == 0) ? stdout : fopen(argv[2], "w");
  if(output == NULL) {
    fprintf(stderr, "Failed to open output file!\n");
    exit(EXIT_FAILURE);
  }

  maps[0] = newStringTable();
  maps[1] = NULL;
  initLexer(input);
  int result = yyparse();
  finalizeLexer();

  fclose(input);
  fclose(output);

  freeStringTable(maps[0]);
  if (maps[1]) {
    freeStringTable(maps[1]);
  }
  free(lists);

  return EXIT_SUCCESS;
}
