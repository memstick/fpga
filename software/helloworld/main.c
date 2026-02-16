
#define VIDEOBUFFER_P 0x80000000

void print(const char * s, int position){
	volatile char *p = (volatile char *) VIDEOBUFFER_P;
	while(*s){
		p[position] = *s;
		s++;
		position++;
		if(position >= (16*3))
			position = 0;
	}
}

void printChar(const char * s, int position){
	volatile char *p = (volatile char *) VIDEOBUFFER_P;
	p[position] = *s;
}

void printInt(int i, int position){

	char c = 48 + i;

	printChar(&c, position);
}

void delay(){
	volatile int i;
	for(i=0; i < 100000; i++){
		(void) i;
	}
}

int main(){

	int dram_ascii = 0;

	print("Hei, verden!", 0);

	while(1){
		print("^^/", 20);
		delay();

		print("^^|", 20);
		delay();

		printInt(dram_ascii, 16);
		dram_ascii++;
		if(dram_ascii > 9) dram_ascii = 0;
	}
	return 0;
}

