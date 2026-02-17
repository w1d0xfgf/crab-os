#include "types.h"
#include "idt.h"

#ifndef PIT_H
#define PIT_H

// Частота PIT в Гц
#define PIT_FREQUENCY 10000

// Секунды в PIT тики
#define SECS_TO_PIT_TICKS(secs) (secs * PIT_FREQUENCY)

void pit_irq_handler(interrupt_frame_t* frame);
void init_pit();
u64 get_pit_ticks();
void pit_sleep_ticks(u8 ticks);

#endif