#include "types.h"

#ifndef SERIAL_H
#define SERIAL_H

u16 serial_get_base(u8 port);
u8 serial_init(u16 base);
u8 serial_transmit(u16 base, u8 byte);
u16 serial_recieve(u16 base);
u8 serial_print(u16 base, const char* str);

#endif