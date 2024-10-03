/* symtab.c: a very simple string table.
 *
 * This string table implementation is not very efficient (linear search for strings)
 * but suffices for the compiler construction labs.
 *
 * author: Arnold Meijster (a.meijster@rug.nl)
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static char *stringTable = NULL; /* The string table itself: a linear array containing strings (including '\0' characters) */
static int strTabSize = 0;       /* Size of the array stringTable */
static int strTabIdx = 0;        /* Index in string table where the next insertion can take place */

static void resize(int sz) {
  /* This function resizes the string tbale in case
   * it can not hold another sz characters.
   */
  if (strTabIdx + sz >= strTabSize) {
    strTabSize = (strTabSize == 0 ? 2 : 2*strTabSize);
    while (strTabIdx + sz >= strTabSize) {
      strTabSize *= 2;
    }
    stringTable = realloc(stringTable, strTabSize);
  }
}

int lookupStringTable(char *str) {
  /* This function returns -1 if the str is not in the string table,
   * otherwise it returns the index idx in the table where str is
   * found (i.e. strcmp(stringTable[idx],str)==0).
   */
  int idx=0, length=strlen(str);
  while (idx < strTabIdx) {
    int len = strlen(&stringTable[idx]);
    if ((length == len) && (strcmp(&stringTable[idx], str) == 0)) {
      return idx;
    }
    idx = idx + len + 1;
  }
  return -1; /* not found */
}

int insertOrRetrieveStringTable(char *str) {
  /* This function inserts str in the string table if it
   * was not already in the table, otherwise it does not alter the table.
   * In both case, it returns the index in the string
   * table where str is stored (i.e. strcmp(stringTable[idx],str)==0).
   */
  int idx = lookupStringTable(str);
  if (idx == -1) { /* not found => insert */
    int len = 1 + strlen(str); /* extra 1 because of terminating '\0' character */
    resize(len); /* make sure there is sufficient space in the table */
    strcpy(&stringTable[strTabIdx], str); /* strcpy copies str including '\0' */
    idx = strTabIdx;
    strTabIdx += len;
  }
  return idx;
}

void showStringTable() {
  /* This function prints the string Table to standard output */
  int idx=0;
  while (idx < strTabIdx) {
    printf("%d: %s\n", idx, &stringTable[idx]);
    idx = idx + strlen(&stringTable[idx]) + 1;
  }
}

void freeStringTable() {
  /* deallocate memory used by the string table */
  free(stringTable);
  stringTable = NULL;
  strTabSize = 0;
}

