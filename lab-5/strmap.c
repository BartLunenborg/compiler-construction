/** @file   strmap.c
 *  @brief  A string table implemented as hash table.
 *  @author Bart Lunenborg, s3410579
 */

#include "strmap.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define INITIAL_CAPACITY 100
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
      fprintf(stderr, "RESIZING MAP!!\n");
      resize(map);
    }
    idx = hashFunction(str) % map->capacity;
    while (map->symbols[idx].str) {
      idx = (idx + 1) % map->capacity;
    }
    map->size++;
    map->symbols[idx] = (Symbol) {strdup(str), 0, 0, 0, 0, 0, 0, 0, 0};
  }
  return idx;
}

void copyToLocalScope(HashMap *global, HashMap *local, char *str) {
  int gIdx = lookupStringTable(global, str);
  int lIdx = insertOrRetrieveStringTable(local, str);
  local->symbols[lIdx].type = global->symbols[gIdx].type;
  local->symbols[lIdx].lower = global->symbols[gIdx].lower;
  local->symbols[lIdx].upper = global->symbols[gIdx].upper;
  local->symbols[lIdx].ival = global->symbols[gIdx].ival;
  local->symbols[lIdx].dval = global->symbols[gIdx].dval;
  int numParams = global->symbols[gIdx].numParams;
  local->symbols[lIdx].numParams = numParams;
  local->symbols[lIdx].params = calloc(numParams, sizeof(Param));
  for (int i = 0; i < numParams; i++) {
    local->symbols[lIdx].params[i].type = global->symbols[gIdx].params[i].type;
    local->symbols[lIdx].params[i].lower = global->symbols[gIdx].params[i].lower;
    local->symbols[lIdx].params[i].upper = global->symbols[gIdx].params[i].upper;
    local->symbols[lIdx].params[i].ref = global->symbols[gIdx].params[i].ref;
  }
}

int expectedNumArguments(HashMap *map, char *str) {
  int idx = lookupStringTable(map, str);
  return idx > -1 ? map->symbols[idx].numParams : idx;
}

void setType(HashMap *map, int idx, Type type) {
  map->symbols[idx].type = type;
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

void setVal(HashMap *map, int idx, double val) {
  if (map->symbols[idx].type == INTNUM || map->symbols[idx].type == INTCON) {
    map->symbols[idx].ival = (int)val;
  } else {
    map->symbols[idx].dval = val;
  }
}

int isArrayType(HashMap *map, int idx) {
  Type type = map->symbols[idx].type;
  return type == ARROR || type == ARROI;
}

int assignArrayTypes(HashMap *map, Type type, int lower, int upper, int isParam) {
  int changed = 0;
  type = type == REALNUM ? ARROR : ARROI;
  for (int i = 0; i < map->capacity; i++) {
    if (map->symbols[i].str && map->symbols[i].type == NONE) {
      changed++;
      map->symbols[i].type = type;
      map->symbols[i].lower = lower;
      map->symbols[i].upper = upper;
      map->symbols[i].isParam = isParam;
    }
  }
  return changed;
}

int assignTypes(HashMap *map, Type type, int isRef, int isParam) {
  int changed = 0;
  for (int i = 0; i < map->capacity; i++) {
    if (map->symbols[i].str && map->symbols[i].type == NONE) {
      changed++;
      map->symbols[i].type = type;
      map->symbols[i].isRef = isRef;
      map->symbols[i].isParam = isParam;
    }
  }
  return changed;
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
  newList->buffs = calloc(1, sizeof(ArithBuff));
  newList->buffs[0].buff = malloc(1024);
  newList->buffs[0].raw = malloc(1024);
  newList->buffs[0].asRef = malloc(1024);
  newList->len = 0;
  lists[len-1] = newList;
  return lists;
}

ArithExprList **freeList(ArithExprList **lists, int len) {
  for (int i = 0; i <= lists[len]->len; i++) {
    free(lists[len]->buffs[i].buff);
    free(lists[len]->buffs[i].raw);
    free(lists[len]->buffs[i].asRef);
  }
  free(lists[len]->buffs);
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
  lists[idx]->items[lists[idx]->len-1] = (ArithExprItem) {type, 0, 0, lower, upper}; 
  if (isIntegerType(type)) { 
    lists[idx]->items[lists[idx]->len-1].ival = (int) val;
  } else {
    lists[idx]->items[lists[idx]->len-1].dval = val;
  }
  lists[idx]->buffs = realloc(lists[idx]->buffs, (lists[idx]->len + 1) * sizeof(ArithBuff));
  lists[idx]->buffs[lists[idx]->len].buff = malloc(1024);
  lists[idx]->buffs[lists[idx]->len].raw = malloc(1024);
  lists[idx]->buffs[lists[idx]->len].asRef = malloc(1024);
  lists[idx]->buffs[lists[idx]->len].buffI = 0;
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
