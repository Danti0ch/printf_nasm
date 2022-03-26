#include <stdio.h>
extern "C" int prinft(const char* str, ...);

int main(){
    prinft("%d %d %d %d %d %d %d %d %d %d %d\n"
           "I %s %x %d%%%c%b",
                1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
                "LOVE", 3802, 100, 33, 15);
    return 0;
}
