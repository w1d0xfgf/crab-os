#include "types.h"

#ifndef KEYBOARD_H
#define KEYBOARD_H

__attribute__((interrupt("IRQ")))
void kbrd_irq_handler(interrupt_frame_t* frame);
u8 kbrd_init();
u16 kbrd_read_scancode();
u16 kbrd_wait_scancode();
bool kbrd_get_key_pressed(u8 key);

#endif