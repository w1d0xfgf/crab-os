#include "types.h"
#include "idt.h"

#ifndef PIT_H
#define PIT_H

void pit_irq_handler(interrupt_frame_t* frame);
void pit_program(u8 mode, u32 frequency);
u32 get_pit_ticks();
void pit_sleep_ticks(u32 ticks);

#endif