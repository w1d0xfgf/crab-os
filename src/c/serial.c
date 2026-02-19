#include "ports.h"
#include "serial.h"

// Регистры
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

// Получить Base
u16 serial_get_base(u8 port) {
	switch (port) {
		case 0:
			return 0x3F8;
			break;
		case 1:
			return 0x2F8;
			break;
		case 2:
			return 0x3E8;
			break;
		case 3:
			return 0x2E8;
			break;
		default:
			return 0;
			break;
	}
}

// Инициализировать COM порт
u8 serial_init(u16 base) {
	// Выключить прерывания
	outb(base + INT_OFFSET, 0);

	// Установить Baud Rate 2400
	{
		// Включить DLAB
		u8 lcr = inb(base + LCR_OFFSET);
		lcr |= 0b10000000;
		outb(base + LCR_OFFSET, lcr);

		// Делитель
		u16 divisor = 115200 / 2400;
		outb(base + DIV_HI_OFFSET, (u8)(divisor >> 8));
		outb(base + DIV_LO_OFFSET, (u8)divisor);

		// Выключить DLAB
		lcr = inb(base + LCR_OFFSET);
		lcr &= 0b01111111;
		outb(base + LCR_OFFSET, lcr);
	}
	
	// 8 бит данных, 1 бит Stop, без битов Parity
	{
		u8 lcr = inb(base + LCR_OFFSET);
		lcr |= 0b00000011;
		lcr &= 0b11000011;
		outb(base + LCR_OFFSET, lcr);
	}

	// FIFO включено, очистить буферы
	outb(base + FIFO_OFFSET, 0b11000111);

	// Включить IRQ, подать сигналы DSR и RTS
	outb(base + MCR_OFFSET, 0b00001011);

	// Loopback
	outb(base + MCR_OFFSET, 0b00011110);

	// Протестировать
	outb(base + BUF_OFFSET, 0xA5);
	if (inb(base + BUF_OFFSET) != 0xA5) return 1;

	// Выйти из Loopback
	outb(base + MCR_OFFSET, 0b00001011);

	return 0;
}

// Отправить один байт через COM порт
u8 serial_transmit(u16 base, u8 byte) {
	// Подождать пока буфер станет пустым и отправить байт
	for (u32 i = 0; i < 1000000; i++) {
		if (inb(base + STATUS_OFFSET) & 0b00100000) {
			outb(base + BUF_OFFSET, byte);
			return 0;
		}
	}
	return 1;
}

// Получить один байт через COM порт
u16 serial_recieve(u16 base) {
	// Подождать пока появятся данные и получить байт
	for (u32 i = 0; i < 1000000; i++) {
		if (inb(base + STATUS_OFFSET) & 0b00000001) return inb(base + BUF_OFFSET) & 0xFF;
	}
	return 0xFFFF;
}

// Попробовать получить один байт через COM порт
u16 serial_try_recieve(u16 base) {
	if (inb(base + STATUS_OFFSET) & 0b00000001) return inb(base + BUF_OFFSET) & 0xFF;
	return 0xFFFF;
}

// Отправить строку в COM порт
u8 serial_print(u16 base, const char* str) {
	for (u32 i = 0; ; i++) {
		char chr = str[i];
		if (!chr) return 0;

		if (serial_transmit(base, chr) != 0) return 1;
	}
}