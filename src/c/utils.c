#include "types.h"
#include "utils.h"

// |x|
i32 abs(i32 x) {
	return (x < 0) ? -x : x;
}

// Копировать участок памяти
void* memcpy(void *dest, const void *src, u32 n) {
	for (u32 i = 0; i < n; i++) {
		((u8*)dest)[i] = ((u8*)src)[i];
	}
	return dest;
}