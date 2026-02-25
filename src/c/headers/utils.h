#include "types.h"

#ifndef UTILS_H
#define UTILS_H

i32 abs(i32 x);
void* memcpy(void* dest, const void* src, u32 n);
void* memset(void* ptr, u8 value, u32 n);

#endif