#include "vga.h"
#include "idt.h"
#include "types.h"
#include "keyboard.h"
#include "pic.h"
#include "pit.h"
#include "print.h"
#include "cmos.h"
#include "pmm.h"
#include "utils.h"

int kmain(memory_map_entry_t* memory_map) {
	// Инициализировать PIC с размаскированным IRQ0 и IRQ1
	pic_init(0b11111100, 0b11111111);

	// Инициализировать IDT с пустыми записями
	idt_init();
	
	// Записать ISR PIT в IDT и инициализировать PIT
	init_pit();
	idt_set_entry(0x20, &pit_irq_handler, 0x8E);

	// Записать ISR клавиатуры в IDT
	idt_set_entry(0x21, &kbrd_irq_handler, 0x8E);

	// Включить прерывания
	__asm__ volatile ("sti");
	
	// Инициализировать VGA
	vga_disable_blink();
	vga_set_cursor(0, 16);
	vga_flush_buffer();

	// Сделать структуру консоли для вывода на экран
	console_t con;
	con.x = 0;
	con.y = 0;
	con.attr = VGA_WHITE;

	// Проверить существует ли карта памяти
	{
		bool memory_map_valid = false;

		// Если хотя бы одной записи корректный, карта памяти существует и корректна
		for (u32 i = 0; i < 128; i++) {
			// Получить запись из карты
			memory_map_entry_t entry = memory_map[i];
			
			if (entry.type > 0 && entry.type < 4) {
				memory_map_valid = true;
				break;
			}
		}
		if (!memory_map_valid) {
			// Вывести сообщение
			printf(&con, "Memory map invalid (your BIOS does not support E820 maps)\r\n");
			vga_flush_buffer();
			vga_update_cursor(&con);
			return 0;
		}
	}

	// Инициализировать PMM
	pmm_init(memory_map);

	// Вывести карту памяти
	for (u32 row = 0; row < 16; row++) {
		for (u32 col = 0; col < 64; col++) {
			if (pmm_bitmap_test(row * 64 + col)) {
				printf(&con, "#");
			} else {
				printf(&con, "-");
			}
		}
		printf(&con, "\r\n");
	}
	vga_flush_buffer();
	vga_update_cursor(&con);
	
	return 0;
}