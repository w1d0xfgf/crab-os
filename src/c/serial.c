#include "ports.h"
#include "serial.h"

// Порты
#define COM1_BASE		0x3F8

// Смещения регистров
#define BUF_OFFSET		0x00
#define DIV_LO_OFFSET	0x00
#define INT_OFFSET		0x01
#define DIV_HI_OFFSET	0x01
#define IIR_OFFSET		0x02
#define FIFO_OFFSET		0x02
#define LCR_OFFSET		0x03
#define MCR_OFFSET		0x04
#define STATUS_OFFSET	0x05
#define MSR_OFFSET		0x06
#define SCRATCH_OFFSET	0x07

// Инициализировать COM порт
void serial_init() {
	// Выключить прерывания
	outb(COM1_BASE + INT_OFFSET, 0);

	// Установить Baud Rate 2400
	{
		// Включить DLAB
		u8 lcr = inb(COM1_BASE + LCR_OFFSET);
		lcr |= 0b10000000;
		outb(COM1_BASE + LCR_OFFSET, lcr);

		// Делитель
		u16 divisor = 115200 / 2400;
		outb(COM1_BASE + DIV_HI_OFFSET, (u8)(divisor >> 8));
		outb(COM1_BASE + DIV_LO_OFFSET, (u8)divisor);

		// Выключить DLAB
		lcr = inb(COM1_BASE + LCR_OFFSET);
		lcr &= 0b01111111;
		outb(COM1_BASE + LCR_OFFSET, lcr);
	}
	
	// 8 бит данных, 1 бит Stop, без битов Parity
	{
		u8 lcr = inb(COM1_BASE + LCR_OFFSET);
		lcr |= 0b00000011;
		lcr &= 0b11000011;
		outb(COM1_BASE + LCR_OFFSET, lcr);
	}

	// FIFO включено, очистить буферы
	outb(COM1_BASE + FIFO_OFFSET, 0b11000111);

	// Включить IRQ, подать сигналы DSR и RTS
	outb(COM1_BASE + MCR_OFFSET, 0b00001011);
}

// Отправить один байт через COM порт
void serial_transmit(u8 byte) {
	// Подождать пока буфер станет пустым и отправить байт
	while ((inb(COM1_BASE + STATUS_OFFSET) & 0b00100000) == 0);
	outb(COM1_BASE + BUF_OFFSET, byte);
}

// Получить один байт через COM порт
u8 serial_recieve() {
	// Подождать пока появятся данные и получить байт
	while ((inb(COM1_BASE + STATUS_OFFSET) & 0b00000001) == 0);
	return inb(COM1_BASE + BUF_OFFSET);
}

// Отправить строку в COM порт
void serial_print(const char* str) {
	for (u32 i = 0; ; i++) {
		char chr = str[i];
		if (!chr) break;

		serial_transmit(chr);
	}
}