#include "types.h"

#ifndef PORTS_H
#define PORTS_H

static inline void outb(u16 port, u8 val) {
	__asm__ volatile ("outb %b0, %w1" : : "a"(val), "Nd"(port) : "memory");
}

static inline u8 inb(u16 port) {
	u8 ret;
	__asm__ volatile ("inb %w1, %b0" : "=a"(ret) : "Nd"(port) : "memory");
	return ret;
}

static inline void io_wait() {
	outb(0x80, 0x00);
}

#endif