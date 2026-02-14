#include "types.h"

#ifndef KEYBOARD_H
#define KEYBOARD_H

#define KBC_DATA 0x60
#define KBC_CMD 0x64

__attribute__((interrupt("IRQ")))
void kbrd_irq_handler(interrupt_frame_t* frame);
u16 kbrd_get_last_scancode();
bool kbrd_get_key_pressed(u8 key);

#endif