/** @file   strmap.c
 *  @brief  A string table implemented as hash table.
 *  @author Bart Lunenborg, s3410579
 */

#include "strmap.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define INITIAL_CAPACITY 50
#define LOAD_FACTOR 0.75

// Creates a new empty hash map with capacity = INITIAL_CAPACITY
HashMap *newStringTable() {
  HashMap *map = malloc(sizeof(HashMap));
  map->symbols = calloc(INITIAL_CAPACITY, sizeof(Symbol));
  map->capacity = INITIAL_CAPACITY;
  map->size = 0;
  return map;
}

// djb2 hash function
unsigned long hashFunction(char *str) {
  unsigned long hashValue = 5381;
  int c;
  while ((c = *str++)) {
    hashValue = ((hashValue << 5) + hashValue) + c;
  }
  return hashValue;
}

// return found str ? index : -1
int lookupStringTable(HashMap *map, char *str) {
  int idx = hashFunction(str) % map->capacity;
  while (map->symbols[idx].str) {
    if (strcmp(map->symbols[idx].str, str) == 0) {
      return idx;  // found
    }
    idx = (idx + 1) % map->capacity;
  }
  return -1;  // not found
}

// Resizes the map by doubling the capacity.
// All symbols get rehashed using the new capacity.
void resize(HashMap *map) {
  int newSize = 0;
  int newCapacity = map->capacity * 2;
  Symbol *newSymbols = calloc(newCapacity, sizeof(Symbol));
  // Rehash all symbols into the new array
  for (int i = 0; i < map->capacity; i++) {
    if (map->symbols[i].str) {
      int idx = hashFunction(map->symbols[i].str) % newCapacity;
      while (newSymbols[idx].str) {
        idx = (idx + 1) % newCapacity;  // Linear probing
      }
      newSymbols[idx] = map->symbols[i];
      newSize++;
    }
  }
  free(map->symbols);
  map->symbols = newSymbols;
  map->capacity = newCapacity;
  map->size = newSize;
}

// Inserts str in the string table if it was not already in the table.
// Returns index of the location of str in the table.
int insertOrRetrieveStringTable(HashMap *map, char *str) {
  int idx = lookupStringTable(map, str);
  if (idx == -1) {  // not found => insert
    if ((double)map->size / map->capacity >= LOAD_FACTOR) {
      resize(map);
    }
    idx = hashFunction(str) % map->capacity;
    while (map->symbols[idx].str) {
      idx = (idx + 1) % map->capacity;
    }
    map->size++;
    map->symbols[idx] = (Symbol) {strdup(str), 0, 0, 0, 0, 0, 0, 0};
  }
  return idx;
}

int expectedNumArguments(HashMap *map, char *str) {
  int idx = lookupStringTable(map, str);
  return map->symbols[idx].numParams;
}

void setType(HashMap *map, int idx, Type type) {
  map->symbols[idx].type = type;
}

Type isConstantType(HashMap *map, int idx) {
  return map->symbols[idx].type == INTCON || map->symbols[idx].type == REALCON;
}

int isIntegerType(Type type) {
  return type == INTNUM || type == INTCON || type == FUNCI;
}

int isRealType(Type type) {
  return type == REALNUM || type == REALCON || type == FUNCR;
}

int typeFromIdx(HashMap *map, int idx) {
  return map->symbols[idx].type;
}

int typeFromStr(HashMap *map, char *str) {
  int idx = lookupStringTable(map, str);
  return map->symbols[idx].type;
}

int typeFromArr(Type t) {
  return t == ARROI ? INTNUM : REALNUM;
}

char *typeAsString(Type type) {
  switch (type) {
    case NONE:    return "NONE"; break;
    case REALNUM: return "REAL_NUM"; break;
    case INTNUM:  return "INTEGER_NUMBER"; break;
    case REALCON: return "REAL_CONSTANT"; break;
    case INTCON:  return "INTERGER_CONSTANT"; break;
    case FUNCI:   return "FUNTION_RETURNING_INTEGER"; break;
    case FUNCR:   return "FUNCTION_RETURNING_REAL"; break;
    case PROC:    return "PROCEDURE"; break;
    case ARROI:   return "ARRAY_OF_INTEGERS"; break;
    case ARROR:   return "ARRAY_OR_REALS"; break;
    }
}

int typeCanBeRhs(Type t) {
  return t == REALNUM || t == INTNUM || t == REALCON || t == INTCON || t == FUNCI || t == FUNCR ;
}

void setVal(HashMap *map, int idx, double val) {
  if (map->symbols[idx].type == INTNUM || map->symbols[idx].type == INTCON) {
    map->symbols[idx].ival = (int)val;
  } else {
    map->symbols[idx].dval = val;
  }
}

int assignArrayTypes(HashMap *map, Type type, int lower, int upper) {
  int changed = 0;
  type = type == REALNUM ? ARROR : ARROI;
  for (int i = 0; i < map->capacity; i++) {
    if (map->symbols[i].str && map->symbols[i].type == NONE) {
      changed++;
      map->symbols[i].type = type;
      map->symbols[i].lower = lower;
      map->symbols[i].upper = upper;
    }
  }
  return changed;
}

int assignTypes(HashMap *map, Type type) {
  int changed = 0;
  for (int i = 0; i < map->capacity; i++) {
    if (map->symbols[i].str && map->symbols[i].type == NONE) {
      changed++;
      map->symbols[i].type = type;
    }
  }
  return changed;
}

// e: expected, a: actual
int isValidParamType(Param e, ArithExprItem a) {
  if (e.type == a.type || 
      isIntegerType(e.type) && isIntegerType(a.type) ||
      isRealType(e.type) && isRealType(a.type)
    ) {  // Obvious case
    return 1;
  }

  if (isRealType(e.type) && isIntegerType(a.type)) {  // Promotion
    return 1;
  }
  if (e.type == ARROR && a.type == ARROI) {  // Array promotion
    return 1;  // Check for size elsewhere
  }
  return 0;
}

void addParams(HashMap *map, char *func, int count, Type type, int lower, int upper, int ref) {
  int idx = lookupStringTable(map, func);
  if (map->symbols[idx].numParams == 0) {
    map->symbols[idx].numParams = count;
    map->symbols[idx].params = malloc(count * sizeof(Param));
  } else {
    map->symbols[idx].numParams += count;
    map->symbols[idx].params = realloc(map->symbols[idx].params, map->symbols[idx].numParams * sizeof(Param));
  }
  int offset = map->symbols[idx].numParams - count;
  for (int i = 0; i < count; i++) {
    map->symbols[idx].params[offset+i].type = type;
    map->symbols[idx].params[offset+i].lower = lower;
    map->symbols[idx].params[offset+i].upper = upper;
    map->symbols[idx].params[offset+i].ref = ref;
  }
}

ArithExprList **addList(ArithExprList **lists, int len) {
  lists = realloc(lists, len * sizeof(ArithExprList *));
  ArithExprList *newList = malloc(sizeof(ArithExprList));
  newList->items = malloc(sizeof(ArithExprItem));
  newList->len = 0;
  lists[len-1] = newList;
  return lists;
}

ArithExprList **freeList(ArithExprList **lists, int len) {
  free(lists[len]->items);
  free(lists[len]);
  if (len == 0) {
    free(lists);
    return NULL;
  } else {
    return realloc(lists, len * sizeof(ArithExprList *));
  }
}

void addArithExpr(ArithExprList **lists, int idx, Type type, double val, int lower, int upper) {
  lists[idx]->len++;
  lists[idx]->items = realloc(lists[idx]->items, lists[idx]->len * sizeof(ArithExprItem));
  if (isIntegerType(type)) {
    lists[idx]->items[lists[idx]->len-1] = (ArithExprItem) {type, (int)val, 0, lower, upper}; 
  } else {
    lists[idx]->items[lists[idx]->len-1] = (ArithExprItem) {type, 0, val, lower, upper}; 
  }
}

void showList(ArithExprItem *list, int size) {
  for (int i = 0; i < size; i++) {
    printf("%s, %d, %lf, %d, %d\n", typeAsString(list[i].type), list[i].ival, list[i].dval, list[i].lower, list[i].upper);
  }
}

// Prints the string table to standard output
void showStringTable(HashMap *map) {
  for (int i = 0; i < map->capacity; i++) {
    if (map->symbols[i].str) {
      printf("%d: %s, %d\n", i, map->symbols[i].str, map->symbols[i].type);
      Type t = map->symbols[i].type;
      if (t == FUNCI || t == FUNCI || t == PROC) {
        for (int j = 0; j < map->symbols[i].numParams; j++) {
          printf("%d: %d ", j, map->symbols[i].params[j].type);
        }
        printf("\n");
      }
    }
  }
}

// deallocate memory used by the string table
void freeStringTable(HashMap *map) {
  for (int i = 0; i < map->capacity; i++) {
    if (map->symbols[i].str) {
      free(map->symbols[i].str);
    }
    if (map->symbols[i].params) {
      free(map->symbols[i].params);
    }
  }
  free(map->symbols);
  free(map);
}
