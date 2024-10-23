/** @file   strhtab.h
 *  @brief  A string table implemented as a hash map.
 *  @author Bart Lunenborg, s3410579
 */

#ifndef __STRMAP_H__
#define __STRMAP_H__

typedef enum Type {
  NONE,     /**< Default to no type             */
  REALNUM,  /**< Real type number.              */
  INTNUM,   /**< Integer type number.           */
  REALCON,  /**< Real constant number.          */
  INTCON,   /**< Integer constant number.       */
  FUNCI,    /**< Function returning an integer. */
  FUNCR,    /**< Function returning a real.     */
  PROC,     /**< Procedure returning nothing.   */
  ARROI,    /**< Array of integer.              */
  ARROR,    /**< Array of real.                 */
} Type;

typedef struct ArithExprItem {
  Type type;
  int ival;
  double dval;
  int lower;
  int upper;
} ArithExprItem;

typedef struct ArithBuff {
  char *buff;
  int buffI;
  char *raw;
  char *asRef;
} ArithBuff;

typedef struct ArithExprList {
  ArithExprItem *items;
  ArithBuff *buffs;
  int len;
} ArithExprList;

typedef struct Param {
  Type type;  /**< The type of the parameter.  */
  int lower;  /**< The lower bound (if array). */
  int upper;  /**< The upper bound (if array). */
  int ref;    /**< 1 if pass by ref, else 0.   */
} Param;

/**
 * A symbol represent an entry into the hash map.
 */
typedef struct Symbol {
  char *str;      /**< The Symbol's string.                 */
  Type type;      /**< The symbol's type.                   */
  int lower;      /**< Upper bound for array if Type = ARR. */
  int upper;      /**< Lower bound for array if type = arr. */
  int ival;       /**< Field that can be used for integers. */
  double dval;    /**< Field that can be used for doubles.  */
  int numParams;  /**< The number of parameters in params.  */
  Param *params;  /**< Array of parameters (for functions). */
  int isParam;
  int isRef;
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

int expectedNumArguments(HashMap *map, char *str);

void setType(HashMap *map, int idx, Type type);

Type isConstantType(HashMap *map, int idx);

int isIntegerType(Type type);

int isRealType(Type type);

int typeFromIdx(HashMap *map, int idx);

int typeFromStr(HashMap *map, char *str);

int typeFromArr(Type type);

char *typeAsString(Type type);

int typeCanBeRhs(Type type);

void setVal(HashMap *map, int idx, double val);

int assignArrayTypes(HashMap *map, Type type, int lower, int upper, int isParam);

int isArrayType(HashMap *map, int idx);

int canBeLhs(HashMap *map, int idx, int scope);

int isFuncType(HashMap *map, int idx);

int assignTypes(HashMap *map, Type type, int isRef, int isParam);

void addParams(HashMap *map, char *func, int vars, Type type, int lower, int upper, int ref);

void addArithExpr(ArithExprList **list, int len, Type type, double val, int lower, int upper);

ArithExprList **addList(ArithExprList **list, int len);

ArithExprList **freeList(ArithExprList **list, int len);

int isValidParamType(Param e, ArithExprItem a);

int typeGetsTruncated(Param e, ArithExprItem a);

int isValidArraySlice(Param e, ArithExprItem a);

int isInRange(HashMap *map, int idx, int i);

void copyToLocalScope(HashMap *global, HashMap *local, char *str);

const char *arrBoundsAsString(HashMap *map, int idx);

void showList(ArithExprItem *list, int size);

/**
 * Deallocates all memory that is used by the hash map.
 */
void freeStringTable(HashMap *map);

#endif
