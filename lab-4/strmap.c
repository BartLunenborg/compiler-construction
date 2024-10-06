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
      return map->symbols[idx].tombstone ? -1 : idx;  // found
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
  // Rehash all non-tombstone symbols into the new array
  for (int i = 0; i < map->capacity; i++) {
    if (map->symbols[i].str && !map->symbols[i].tombstone) {
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
      printf("Resizing at: %d\n", map->size);
      resize(map);
    }
    idx = hashFunction(str) % map->capacity;
    while (map->symbols[idx].str && !map->symbols[idx].tombstone) {
      idx = (idx + 1) % map->capacity;
    }
    if (map->symbols[idx].tombstone) {
      free(map->symbols[idx].str);
    } else {
      map->size++;
    }
    map->symbols[idx] = (Symbol) {strdup(str), 0};
  }
  return idx;
}

// Deletes a symbol from the hash map
void deleteFromStringTable(HashMap *map, char *str) {
  int idx = hashFunction(str) % map->capacity;
  while (map->symbols[idx].str) {
    if (strcmp(map->symbols[idx].str, str) == 0) {
      map->symbols[idx].tombstone = 1;
      return;
    }
    idx = (idx + 1) % map->capacity;
  }
}

// Prints the string table to standard output
void showStringTable(HashMap *map) {
  for (int i = 0; i < map->capacity; i++) {
    if (map->symbols[i].str && !map->symbols[i].tombstone) {
      printf("%d: %s\n", i, map->symbols[i].str);
    }
  }
}

// deallocate memory used by the string table
void freeStringTable(HashMap *map) {
  for (int i = 0; i < map->capacity; i++) {
    if (map->symbols[i].str) {
      free(map->symbols[i].str);
    }
  }
  free(map->symbols);
  free(map);
}
