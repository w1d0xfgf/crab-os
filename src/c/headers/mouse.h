#include "types.h"
#include "idt.h"

#ifndef MOUSE_H
#define MOUSE_H

typedef struct {
	i16 dx, dy;
	bool lmb;
	bool rmb;
	bool mmb;
} mouse_state_t;

void mouse_irq_handler(interrupt_frame_t* frame);
u8 mouse_init();
mouse_state_t mouse_get_state();

#endif