/** @file   strhtab.h
 *  @brief  A string table implemented as a hash map.
 *  @author Bart Lunenborg, s3410579
 */

#ifndef __STRMAP_H__
#define __STRMAP_H__

/**
 * A symbol represent an entry into the hash map.
 */
typedef struct Symbol {
  char *str;      /**< The Symbol's string.                         */
  int tombstone;  /**< Indicates whether a Symbol has been deleted. */
} Symbol;


/**
 * A hash map for storing Symbols.
 */
typedef struct HashMap {
  Symbol *symbols;  /**< The array of Symbols.                        */
  int capacity;     /**< The capacity of the hash map.                */
  int size;         /**< The current number of items in the hash map. */
} HashMap;


/**
 * Generate a new empty hash map that dynamically grows.
 * Must be freed by caller using freeStringTable!
 * @return  A pointer to the new HashMap.
 */
HashMap *newStringTable();


/**
 * Looks up a string in the hash map.
 * @param str  The string to look up.
 * @return     Found str ? index of str : -1.
 */
int lookupStringTable(HashMap *map, char *str);


/**
 * Inserts a string in the hash map if it is not there already,
 * otherwise the map is not altered.
 * @param str  The string to insert.
 * @return     The index in the hash map where str is stored.
 */
int insertOrRetrieveStringTable(HashMap *map, char *str);


/**
 * Deletes an entry from the hash map by setting the tombstone flag.
 * @param map  The hash map.
 * @param str  The string to delete.
 */
void deleteFromStringTable(HashMap *map, char *str);

/**
 * Shows the entire string map on standard output.
 */
void showStringTable(HashMap *map);


/**
 * Deallocates all memory that is used by the hash map.
 */
void freeStringTable(HashMap *map);

#endif
