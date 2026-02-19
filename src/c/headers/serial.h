#include "types.h"

#ifndef SERIAL_H
#define SERIAL_H

void serial_init();
void serial_transmit(u8 byte);
void serial_print(const char* str);

#endif