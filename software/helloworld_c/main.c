
#define VIDEOBUFFER_P 0x80000000
#define UART_BASE     0x20000000
#define UART_CTRL     (UART_BASE + 0x0)
#define UART_DATA_RD  (UART_BASE + 0x4)
#define UART_DATA_WR  (UART_BASE + 0x8)

#define SDRAM_TEST_START 0x00001000u
#define SDRAM_TEST_END   0x01000000u

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

static void uart_puthex(const unsigned char v){

    switch(v & 0xF){
        case 0 : uart_putc('0'); break;
        case 1 : uart_putc('1'); break;
        case 2 : uart_putc('2'); break;
        case 3 : uart_putc('3'); break;
        case 4 : uart_putc('4'); break;
        case 5 : uart_putc('5'); break;
        case 6 : uart_putc('6'); break;
        case 7 : uart_putc('7'); break;
        case 8 : uart_putc('8'); break;
        case 9 : uart_putc('9'); break;
        case 0xa : uart_putc('a'); break;
        case 0xb : uart_putc('b'); break;
        case 0xc : uart_putc('c'); break;
        case 0xd : uart_putc('d'); break;
        case 0xe : uart_putc('e'); break;
        case 0xf : uart_putc('f'); break;
    }
}

static void uart_put_u32(unsigned int v){
    int n = 8;
    for(n=28; n >= 0; n-=4){
        uart_puthex((const unsigned char) ((v >> n) & 0xF));
    }
}

static void uart_put_dec_u32(unsigned int v){
	/* Fast path for 0-100 without division/mod. */
	if (v >= 100u) {
		uart_putc('1');
		uart_putc('0');
		uart_putc('0');
		return;
	}
	if (v >= 10u) {
		unsigned int tens = 0;
		while (v >= 10u) {
			v -= 10u;
			tens++;
		}
		uart_putc((char)('0' + tens));
		uart_putc((char)('0' + v));
		return;
	}
	uart_putc((char)('0' + v));
}

static inline int uart_rx_ready(void){
	volatile unsigned int *ctrl = (unsigned int *) UART_CTRL;
	return (*ctrl & 0x2) != 0;
}

static inline char uart_getc(void){
	volatile unsigned int *data = (unsigned int *) UART_DATA_RD;
	return (char)(*data & 0xFF);
}

static unsigned int lfsr32(unsigned int x){
	/* Galois LFSR, taps: 32, 31, 29, 1 */
	unsigned int lsb = x & 1u;
	x >>= 1;
	if (lsb) {
		x ^= 0xD0000001u;
	}
	return x;
}

void delay(){
	volatile int i;
	for(i=0; i < 5000; i++){
		(void) i;
	}
}

static int memtest(void){
	volatile unsigned int *p;
	unsigned int seed = 0xC0FFEE12u;
	unsigned int expected;
	unsigned int sp;
	unsigned int total_words;
	unsigned int count;
	unsigned int percent;
	unsigned int acc;

	__asm__ volatile ("mv %0, sp" : "=r"(sp));
	uart_puts("sp: 0x");
	uart_put_u32(sp);
	uart_puts("\r\n");

	total_words = (SDRAM_TEST_END - SDRAM_TEST_START) / 4u;
	if (total_words == 0) {
		uart_puts("memtest: empty range\r\n");
		return 0;
	}

	uart_puts("memtest: write...\r\n");
	count = 0;
	percent = 0;
	acc = 0;
	for (p = (volatile unsigned int *)SDRAM_TEST_START;
	     p < (volatile unsigned int *)SDRAM_TEST_END; ++p) {
		seed = lfsr32(seed);
		*p = seed ^ (unsigned int)p;
		count++;
		acc += 100u;
		if (acc >= total_words && percent < 100u) {
			acc -= total_words;
			percent++;
			uart_puts("memtest: ");
			uart_put_dec_u32(percent);
			uart_puts("%\r\n");
		}
	}

	seed = 0xC0FFEE12u;
	count = 0;
	percent = 0;
	acc = 0;
	for (p = (volatile unsigned int *)SDRAM_TEST_START;
	     p < (volatile unsigned int *)SDRAM_TEST_END; ++p) {
		seed = lfsr32(seed);
		expected = seed ^ (unsigned int)p;

		if (*p != expected) {
			uart_puts("memtest: FAIL\r\n");
			uart_puts("p: 0x");
			uart_put_u32((unsigned int) p);
			uart_puts(" *p: 0x");
			uart_put_u32((unsigned int) *p);
			uart_puts(" expect: 0x");
			uart_put_u32((unsigned int) expected);
			uart_puts("\r\n");
			uart_puts("memtest: FAIL\r\n");
			return 0;
		}

		count++;
		acc += 100u;
		if (acc >= total_words && percent < 100u) {
			acc -= total_words;
			percent++;
			uart_puts("memtest: ");
			uart_put_dec_u32(percent);
			uart_puts("%\r\n");
		}
	}

	uart_puts("memtest: PASS\r\n");
	return 1;
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

int main(){

	int dram_ascii = 0;

	print("Hei, verden!", 0);
	uart_puts("Hello, world!");
	memtest();

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
