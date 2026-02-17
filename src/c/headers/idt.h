#include "types.h"

#ifndef IDT_H
#define IDT_H

// Фрейм прерывания в x86
typedef struct {
	u32 eip;	// Регистр EIP
	u32 cs;		// Регистр CS
	u32 eflags;	// Регистр EFLAGS
	u32 ss;		// Регистр SS
	u32 es;		// Регистр ES
} __attribute__((packed)) interrupt_frame_t;

void idt_init();
void idt_set_entry(u8 vector, void* isr, u8 flags);

#endif