extern "C" int prinft(const char* str, ...);
//#include <stdio.h>

//extern "C" int sum(int a1, int a2, int a3, int a4, int a5, int a6, int a7, int a8, int a9);

//int sum(int a1, int a2, int a3, int a4, int a5, int a6, int a7, int a8, int a9){
//	if(a1 != 0) int c = sum(0, 2, 3, 4, 5, 6, 7, 8, 9);
//	return a1 + a9;
//}

#include <stdio.h>

int main(){
	prinft("%d %d %d %d %d %d %d %d %d %d %d", 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);
	//prinft("%d, %d", 1, 2);
	//sum(1, 2, 3, 4, 5, 6, 7, 8, 9);
	return 0;
}
