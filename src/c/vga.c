#include "vga.h"
#include "ports.h"
#include "types.h"
#include "utils.h"

// Буфер
static u16 buffer[80 * 25];

// V-Blank?
static bool is_vblank() {
	return inb(0x3DA) & 0x08;
}

// Подождать V-Blank
static void wait_vblank() {
	// Бит 3 в 0x3DA означает V-Blank
	while (!is_vblank());
}

// Записать один символ в VGA память
static void put(char chr, u8 attr, u16 pos) {
	buffer[pos] = (attr << 8) | chr;
}

// Напечатать один символ
void vga_putc(console_t* con, char chr) {
	switch (chr) {
		case '\n':
			if (con->y >= 24) {
				con->y = 23;
				vga_scroll(con);
			}
			con->y += 1;
			break;
		case '\r':
			con->x = 0;
			break;
		default:
			put(chr, con->attr, con->x + con->y * 80);
			con->x += 1;
			if (con->x >= 80) {
				con->x = 0;
				if (con->y >= 24) {
					con->y = 23;
					vga_scroll(con);
				}
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
			case '\n':
				con->y += 1;
				if (con->y >= 25) {
					con->y = 0;
				}
				break;
			case '\r':
				con->x = 0;
				break;
			default:
				put(chr, con->attr, con->x + con->y * 80);

				con->x += 1;
				if (con->x >= 80) {
					con->x = 0;
					if (con->y >= 24) {
						con->y = 23;
						vga_scroll(con);
					}
					con->y += 1;
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
		buffer[i] = (con->attr << 8) | 0;
	}
	con->x = 0;
	con->y = 0;
}

// Скролл
void vga_scroll(console_t* con) {
	// Скопировать строки 1-24 в 0-23
	for (u32 row = 1; row < 25; row++) {
		memcpy(&buffer[(row - 1) * 80], &buffer[row * 80], 160);
	}
	// Записать нули в строку 24
	for (u32 i = 0; i < 80; i++) {
		buffer[24 * 80 + i] = (con->attr << 8) | 0;
	}
}

// Переместить курсор
void vga_update_cursor(console_t* con) {
	u16 pos = con->y * 80 + con->x;

	outb(0x3D4, 0x0F);
	outb(0x3D5, (u8)(pos & 0xFF));
	outb(0x3D4, 0x0E);
	outb(0x3D5, (u8)((pos >> 8) & 0xFF));
}

// Выключить мигание
void vga_disable_blink() {
	// Сбросить Flip-Flop
	(volatile void)inb(0x3DA);

	// Индекс регистра VGA
	outb(0x3C0, 0x30);

	// Получить регистр VGA
	u8 reg = inb(0x3C1);

	// Blink Enable бит = 0
	reg &= ~(1 << 3);

	// Записать регистр VGA
	outb(0x3C0, reg);
}

// Установить курсор
void vga_set_cursor(u8 start, u8 end) {
	// Индекс
	outb(0x3D4, 0x0A);
	// Запись
	outb(0x3D5, (inb(0x3D5) & 0xC0) | start);

	// Индекс
	outb(0x3D4, 0x0B);
	// Запись
	outb(0x3D5, (inb(0x3D5) & 0xE0) | end);
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

// Попробовать скопировать буфер в VGA память
void vga_try_flush_buffer() {
	if (is_vblank()) {
		// Скопировать
		for (u32 i = 0; i < 80 * 25; i++) {
			*(u16*restrict)(0xB8000 + i * 2) = buffer[i];
		}
	}
}