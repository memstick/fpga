
#define VIDEOBUFFER_P 0x80000000

static unsigned int position = 0;

#if 1
void print(int * s){
	volatile unsigned int *p = (unsigned int *) VIDEOBUFFER_P;
	while(*s){
		p[position] = *((unsigned int *)s);
		s++;
		position++;
		if(position >= (16*3))
			position = 0;
	}
}
#endif

const int arr[5] = {101,102,103,104,0};

int main(){
	unsigned int *p = (unsigned int *) VIDEOBUFFER_P;
	print(arr);
	//print("Hey,verden!");
#if 0
	if(0){
		*p = arr[0];
		p++;
		*p = arr[1];
		p++;
		*p = arr[2];
		p++;
		*p = arr[3];
	}
#endif

	while(1);
	return 0;
}

/*
void  __attribute__((section(".initf"))) early_init(){
	
	__asm__("li sp, 0\r\n");
	main();

}
*/
