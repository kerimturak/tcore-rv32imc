#ifndef TEKNO_H
#define TEKNO_H

#include <stdint.h>

#define CLOCKS_PER_SEC 50000000
#define CPU_CLK CLOCKS_PER_SEC
#define BAUD_RATE 115200

#define UART_STATUS      (*(volatile uint32_t*)0x20000004)
#define UART_RDATA       (*(volatile uint32_t*)0x20000008)
#define UART_WDATA       (*(volatile uint32_t*)0x2000000c)
#define UART_CTRL        (*(volatile uint32_t*)0x20000000)

#define TIMER_LOW        (*(volatile uint32_t*)0x30000000)
#define TIMER_HIGH       (*(volatile uint32_t*)0x30000004)

typedef union
{
	struct {
		unsigned int tx_en    : 1;
		unsigned int rx_en 	  : 1;
		unsigned int null	  : 14;
		unsigned int baud_div : 16;
	} fields;
	uint32_t bits;
}uart_ctrl;

typedef union
{
	struct {
		unsigned int tx_full  : 1;
		unsigned int rx_full  : 1;
		unsigned int tx_empty : 1;
		unsigned int rx_empty : 1;
		unsigned int null	  : 28;
	} fields;
	uint32_t bits;
}uart_status;


void init_uart(){
    uart_ctrl uart_control;
    uart_control.fields.tx_en = 0x1; 
    uart_control.fields.tx_en = 0x1; 
    uart_control.fields.baud_div = CPU_CLK/BAUD_RATE;
    UART_CTRL = uart_control.bits;
}



#endif

