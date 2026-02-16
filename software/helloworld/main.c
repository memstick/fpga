
#define VIDEOBUFFER_P 0x80000000
#define UART_BASE     0x20000000
#define UART_CTRL     (UART_BASE + 0x0)
#define UART_DATA_RD  (UART_BASE + 0x4)
#define UART_DATA_WR  (UART_BASE + 0x8)

static inline void uart_putc(char c){
	volatile unsigned int *ctrl = (unsigned int *) UART_CTRL;
	volatile unsigned int *data = (unsigned int *) UART_DATA_WR;
	while (*ctrl & 0x1) { /* wr_busy */ }
	*data = (unsigned int)(unsigned char)c;
}

static void uart_puts(const char *s){
	while (*s) {
		uart_putc(*s++);
	}
}

static inline int uart_rx_ready(void){
	volatile unsigned int *ctrl = (unsigned int *) UART_CTRL;
	return (*ctrl & 0x2) != 0;
}

static inline char uart_getc(void){
	volatile unsigned int *data = (unsigned int *) UART_DATA_RD;
	return (char)(*data & 0xFF);
}

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
	for(i=0; i < 5000; i++){
		(void) i;
	}
}

int main(){

	int dram_ascii = 0;

	print("Hei, verden!", 0);
	uart_puts("UART hello!\\r\\n");

	while(1){
		if (uart_rx_ready()) {
			char c = uart_getc();
			uart_putc(c);
		}

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
