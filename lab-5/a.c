#include <stdio.h>

// sets arr[idx] = a and then set a = idx.
void f(int *a, int *arr, int idx) {
  int  _t0 = *a;
  int *_t1 = arr;
  _t1  = _t1 + idx;
  *_t1 = _t0;
  int _t2 = *_t1;
  _t0 = _t2;
  _t2 = 4;
}

int main(int argc, char *argv[]) {
  int arr[2] = {1, 2};
  int a = 5;
  printf("a: %d, arr[0] = %d, arr[1] = %d\n", a, arr[0], arr[1]);
  f(&a, arr, 1); 
  printf("a: %d, arr[0] = %d, arr[1] = %d\n", a, arr[0], arr[1]);
  return 0;
}
