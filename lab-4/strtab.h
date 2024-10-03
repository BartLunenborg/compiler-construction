#ifndef STRAB_H
#define STRAB_H
/* symtab.h: a very simple string table.
 *
 * This string table implementation is not very efficient (linear search for strings)
 * but suffices for the compiler construction labs.
 *
 * author: Arnold Meijster (a.meijster@rug.nl)
 */


/* The call lookUpStringTable(str) returns -1 if the str is not
 * in the string table, otherwise it returns the index idx in
 * the table where str is found.
 */
int lookupStringTable(char *str);


/* The call insertOrRetrieveStringTable(str) inserts str in the string
 * table if it was not already in the table, otherwise it does not
 * alter the table. In both case, it returns the index in the string
 * table where str is stored.
 */
int insertOrRetrieveStringTable(char *str);


/* The function showStringTable() shows the entire string table
 * on standard output.
 */
void showStringTable();


/* The all freeStringTable() deallocates all memory that is
 * used by the string table.
 */

void freeStringTable();

#endif
