#include "types.h"

#ifndef PIC_H
#define PIC_H

__attribute__((no_caller_saved_registers))
void pic_send_eoi(u8 irq);
void pic_init(u8 mask1, u8 mask2);

#endif