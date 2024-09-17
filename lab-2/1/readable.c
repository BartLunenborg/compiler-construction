/** @file   readable.c
 *  @author Bart Lunenborg, s3410579
 */

#include <stdio.h>

int accept(char a) {
  char b;
  while ((b = getchar()) == ' ');
  return (b == a) ? 1 : (ungetc(b, stdin), 0);
}

int parse_S();

int parse_A() {
  return accept('a') || (accept('(') && parse_S());
}

int parse_B() {
  if (accept('+')) {
    return parse_S();
  }
  if (accept('*')) {
    return parse_B();
  }
  return accept('\n') || accept(')') || parse_S();
}

int parse_S() {
  return parse_A() && parse_B();
}

int main(int argc, char *argv[]) {
  printf("%s\n", parse_S() && getchar() == EOF ? "SUCCESS" : "FAILURE");
  return 0;
}
