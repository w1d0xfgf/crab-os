#include "types.h"
#include "pmm.h"

static u8 bitmap[PMM_BITMAP_SIZE_PAGES / 8] = {1};

void pmm_bitmap_clear(u32 idx) {
	bitmap[idx / 8] &= ~(1 << (idx % 8));
}

void pmm_bitmap_set(u32 idx) {
	bitmap[idx / 8] |= 1 << (idx % 8);
}

bool pmm_bitmap_test(u32 idx) {
	return bitmap[idx / 8] >> (idx % 8) & 0b00000001;
}

u8 pmm_bitmap_clear_region(u32 idx, u32 length) {
	if (length >= PMM_BITMAP_SIZE_PAGES) return 1;

	for (; idx < (idx + length); idx++) {
		pmm_bitmap_clear(idx);
	}

	return 0;
}