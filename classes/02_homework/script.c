#include <stdio.h>

int main(int argc, char const *argv[]) {
  int origin = 0x100000;
  int subtraction = 0x2AAAA;
  for (int i = 0; i < 7; ++i) {
    printf("%06x\n", origin);
    origin = origin - subtraction;
  }
  return 0;
}