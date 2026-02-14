#include "types.h"

#ifndef VGA_H
#define VGA_H

enum VGA_ATTR {
	VGA_BLACK = 0,
	VGA_BLUE = 1,
	VGA_GREEN = 2,
	VGA_CYAN = 3,
	VGA_RED = 4,
	VGA_MAGENTA = 5,
	VGA_BROWN = 6,
	VGA_GRAY = 7,
	VGA_DARK_GRAY = 8,
	VGA_LIGHT_BLUE = 9,
	VGA_LIGHT_GREEN = 10,
	VGA_LIGHT_CYAN = 11,
	VGA_LIGHT_RED = 12,
	VGA_LIGHT_MAGENTA = 13,
	VGA_YELLOW = 14,
	VGA_WHITE = 15,
};

typedef struct {
	u8 x, y;
	u8 attr;
} console_t;

void vga_putc(console_t* con, char chr);
void vga_print(console_t* con, const char* str);
void vga_clear(console_t* con);
void vga_flush_buffer();
void vga_plot(console_t* con, u8 x, u8 y);
void vga_draw_line(console_t* con, i8 x1, i8 y1, i8 x2, i8 y2);

#endif