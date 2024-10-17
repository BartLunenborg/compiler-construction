# Assumptions
1.  Promotion happens implicitly without warnings or error.
    - Integers can be promoted to reals.
    - Arrays of integers can be promoted to arrays of reals.
    - Functions returning integers can be promoted to functions returning reals.
2.  We don't care about the program's name.
3.  We are allowed to simplify `IDENTIFIER '[' ArithExpr RANGE ArithExpr ']'` to `IDENTIFIER '[' INTNUMBER RANGE INTNUMBER ']'`.
4.  `div` and `mod` are only defined for integer types (and always return integers).
5.  `\` always returns a real.
6.  We don't allow `const` variables to be passed by reference.

# Implemented errors
The errors are implemented such that the program will always continue parsing unless it encounters a syntax error.
1.  Redefinition
    - Redefinition errors occur when an `identifier` is introduced that has already been declared in the current scope.
2.  Undeclared
    - Undeclared errors occur when an `identifier` that should exist is called, but it does not.
3.  Assignment to a constant
    - Occurs when a `const` variable is attempted to be reassigned.
4.  Modulo (type error)
    - My implementation of the `mod` operator allows only integer types to be used with `mod`.
5.  Modulo by zero
    - Although not all values can be know at this stage, if we know it and it is 0 then we give an error, since modulo by 0 is not defined.
6.  Right-hand-side invalid
    - Gives an error if the type of rhs in `:=` does not return a value.
7.  Array indexing (type error)
    - If we try `arr[a]` and `a` is anything but an integer type[^1] we give an error.
8.  No-value
    - Error given when something that doesn't return a single a value is used in arithmetic operations.
9.  Division by zero
    - Although not all values can be know at this stage, if we know it and it is 0 then we give an error, since division by 0 is not defined.
10. (integer) Division (type error)
    - My implementation of the `div` operator allows only integer types to be used with `div`.
11. Truncation
    - When we attempt to assign a `real` type to an `integer` type we give an error.
12. Wrong number of arguments
    - Trying to call a function with the wrong number of arguments.
13. Wrong argument type
    - Trying to call a function, but providing the wrong type of argument(s).
14. Out of bounds (array) or negative indexing
    - Trying to index an array outside it's bound.
15. Invalid range
    - Using a range `[a..b]` where a < b.
16. Wrong range (array slice argument)
    - Using an array slice of the wrong length.
17. Invalid relop type
    - Using an ArithExpr in a relop that can't be used in a relop.
18. Invalid procedure call
    - Using an `identifier` that is not a `procedure` as one that should be (since procedure may not have parameters).
19. Invalid function call
    - Using an `identifier` that is not a `function` or `procedure` as one that should be.
20. Non-array error
    - Using an `identifier` that is not a `array` or as one that should be.
21. Left-hand-side invalid
    - Using an invalid type as Lhs.
    For example: if we have a function `f` and we are in function `g` we cant do `f := 5;`, but we can do `g := 5;`)
22. Invalid writeln type
    - Using a type in `writeln` that should not be used there.
23. Const as ref
    - When a variable declared as `const` is passed by reference we give an error.
24. Function as ref
    - When a function is passed by reference we give an error.
25. Raw numbers as ref
    - When a raw number is passed by reference we give an error (things such as `a * b` or `arr[5] + 9`).
26. Return value ignored
    - When a functions is called but the result is not used (function used as procedure).
17. Function shadowed error
    - When we have defined a function and we try to call it in another function, but it is shadowed by a local variable.

[^1]: Integer types are integer numbers, but also functions return integers and arrays of integers if one element is selected.
