#include "types.h"
#include "pmm.h"

__attribute__((aligned(4)))
static u8 bitmap[PMM_BITMAP_SIZE_PAGES / 8] = {1};

static void pmm_bitmap_clear(u32 idx) {
	bitmap[idx / 8] &= ~(1 << (idx % 8));
}

static void pmm_bitmap_set(u32 idx) {
	bitmap[idx / 8] |= 1 << (idx % 8);
}

static bool pmm_bitmap_test(u32 idx) {
	return bitmap[idx / 8] >> (idx % 8) & 0b00000001;
}

static u8 pmm_bitmap_do_region(u32 idx, u32 length, bool set) {
	if (length > PMM_BITMAP_SIZE_PAGES) return 1;

	for (; idx < (idx + length); idx++) {
		if (set) {
			pmm_bitmap_set(idx);
		} else {
			pmm_bitmap_clear(idx);
		}
	}

	return 0;
}

void pfree(u32 address, u32 length) {
	pmm_bitmap_do_region(address / 4096, (length + 4095) / 4096, false);
}