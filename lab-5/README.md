## Made choices
- We use a very simple stack to keep track of labels.
- If we're building an ArithExprList, then we write to buffers.
  This allows allows the 'caller' print the items in the list how and where it wants.
- We also use buffers in other places where needed.
- We use helper functions to copy arrays when needed.
