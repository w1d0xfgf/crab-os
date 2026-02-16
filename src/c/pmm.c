#include "types.h"
#include "pmm.h"

// Битмап PMM
__attribute__((aligned(4)))
static u8 bitmap[PMM_BITMAP_SIZE_PAGES / 8] = {1};

// Сделать один бит в битмапе 0
static void pmm_bitmap_clear(u32 idx) {
	bitmap[idx / 8] &= ~(1 << (idx % 8));
}

// Сделать один бит в битмапе 1
static void pmm_bitmap_set(u32 idx) {
	bitmap[idx / 8] |= 1 << (idx % 8);
}

// Получить значение одного бита в битмапе
bool pmm_bitmap_test(u32 idx) {
	return bitmap[idx / 8] >> (idx % 8) & 0b00000001;
}

// Заполнить единицами или нулями регион в битмапе
static u8 pmm_bitmap_do_region(u64 idx, u64 length, bool set) {
	// Если длина слишком большая выдать ошибку
	if (length > PMM_BITMAP_SIZE_PAGES) return 1;

	// Пройтись по всем битам от idx до idx + length
	u64 end = (idx + length);
	if (end > PMM_BITMAP_SIZE_PAGES) end = PMM_BITMAP_SIZE_PAGES;
	for (u32 idx2 = idx; (idx2 < end); idx2++) {
		// Установить значение бита
		if (set) {
			pmm_bitmap_set(idx2);
		} else {
			pmm_bitmap_clear(idx2);
		}
	}

	return 0;
}

// Инициализировать PMM из E820 BIOS карты памяти
void pmm_init(memory_map_entry_t* memory_map) {
	// 128 записей
	for (u32 i = 0; i < 128; i++) {
		// Получить запись из карты
		memory_map_entry_t entry = memory_map[i];

		// Если запись соответствует свободному участку памяти освободить этот участок в битмапе
		if (entry.type == 1) {
			pmm_bitmap_do_region(entry.base / 4096, (entry.length + 4095) / 4096, false);
		}
	}

	// Пометить ядро как занято
	pmm_bitmap_do_region(0x8200 / 4096, 0x10000 / 4096, true);

	// Пометить VGA буфер как занято
	pmm_bitmap_do_region(0xB8000 / 4096, 1, true);
}

// Выделить память
allocation_result_t palloc(u32 length) {
	allocation_result_t result;
	result.length = length;
	result.is_error = false;

	u32 length_pages = (length + 4095) / 4096;
	u32 free_length = 0;
	for (u32 idx_byte = 0; idx_byte < PMM_BITMAP_SIZE_PAGES / 8; idx_byte++) {
		if (bitmap[idx_byte] == 0xFF) {
			free_length = 0;
			continue;
		}

		for (u32 idx_bit = 0; idx_bit < 8; idx_bit++) {
			bool is_free = !(bitmap[idx_byte] >> idx_bit & 0b00000001);
			if (is_free) {
				free_length++;
				
				if (free_length >= length_pages) {
					u32 idx = (idx_byte * 8 + idx_bit) - length_pages + 1;
					pmm_bitmap_do_region(idx, length_pages, true);
					result.address = idx * 4096;
					return result;
				}
			} else {
				free_length = 0;
			}
		}
	}

	result.is_error = true;
	return result;
}

// Освободить память
void pfree(allocation_result_t* allocated) {
	if (allocated->is_error) return;
	pmm_bitmap_do_region(allocated->address / 4096, (allocated->length + 4095) / 4096, false);
}