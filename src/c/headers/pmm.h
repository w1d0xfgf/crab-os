#include "types.h"

#ifndef PMM_H
#define PMM_H

#define PMM_BITMAP_SIZE_PAGES 10000

typedef struct {
	u64 base;
	u64 length;
	u32 type;
	u32 reserved;
} __attribute__((packed)) memory_map_entry_t;

typedef struct {
	bool is_error;
	u32 address;
	u32 length;
} allocation_result_t;

void pmm_init(memory_map_entry_t* memory_map);
void pmm_reserve(u32 address, u32 length);
allocation_result_t palloc(u32 length);
void pfree(allocation_result_t* allocated);

#endif