#include "vga.h"
#include "types.h"

#ifndef PRINT_H
#define PRINT_H

void print_decimal(console_t* con, u32 val);
void print_hex(console_t* con, u32 val);
void print_hex_8(console_t* con, u8 val);
void printf(console_t* con, const char* fmt, ...);

#endif