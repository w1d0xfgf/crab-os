#include "vga.h"
#include "ports.h"
#include "types.h"
#include "utils.h"

// Буфер
static u16 buffer[80 * 25];

// Подождать V-Blank
static void wait_vblank() {
	// Бит 3 в 0x3DA означает V-Blank
	while (!(inb(0x3DA) & 0x08));
}

// Записать один символ в VGA память
static void put(char chr, u8 attr, u16 pos) {
	buffer[pos] = (attr << 8) | chr;
}

// Напечатать один символ
void vga_putc(console_t* con, char chr) {
	switch (chr) {
		case 13:
			con->y += 1;
			if (con->y >= 25) {
				con->y = 0;
			}
			break;
		case 10:
			con->x = 0;
			break;
		default:
			put(chr, con->attr, con->x + con->y * 80);
			con->x += 1;
			if (con->x >= 80) {
				con->x = 0;
				con->y += 1;
			}
			break;
	}
}

// Напечатать строку
void vga_print(console_t* con, const char* str) {
	for (;;) {
		char chr = *str;
		if (!chr) break;
		switch (chr) {
			case 13:
				con->y += 1;
				if (con->y >= 25) {
					con->y = 0;
				}
				break;
			case 10:
				con->x = 0;
				break;
			default:
				put(chr, con->attr, con->x + con->y * 80);

				con->x += 1;
				if (con->x >= 80) {
					con->x = 0;
					con->y += 1;
					if (con->y >= 25) {
						con->y = 0;
					}
				}
				break;
		}

		str++;
	}
}

// Нарисовать точку
void vga_plot(console_t* con, u8 x, u8 y) {
	put(0xDB, con->attr, x + y * 80);
}

// Очистить экран
void vga_clear(console_t* con) {
	for (u32 i = 0; i < 80 * 25; i++) {
		buffer[i] = (con->attr << 8) | ' ';
	}
	con->x = 0;
	con->y = 0;
}

// Скопировать буфер в VGA память
void vga_flush_buffer() {
	// Подождать пока кадр закончится (V-Blank время)
	wait_vblank();

	// Скопировать
	for (u32 i = 0; i < 80 * 25; i++) {
		*(u16*restrict)(0xB8000 + i * 2) = buffer[i];
	}
}