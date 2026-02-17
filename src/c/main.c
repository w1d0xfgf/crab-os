#include "vga.h"
#include "idt.h"
#include "types.h"
#include "kbc.h"
#include "keyboard.h"
#include "pic.h"
#include "pit.h"
#include "print.h"
#include "cmos.h"
#include "pmm.h"
#include "utils.h"

int kmain(memory_map_entry_t* memory_map) {
	// Инициализировать VGA
	vga_disable_blink();
	vga_set_cursor(12, 14);
	vga_flush_buffer();

	// Сделать структуру консоли для вывода на экран
	console_t con;
	con.x = 0;
	con.y = 0;
	con.attr = VGA_WHITE;
	vga_clear(&con);
	vga_flush_buffer();
	vga_update_cursor(&con);

	// Инициализировать PIC с размаскированным IRQ0 и IRQ1
	pic_init(0b11111100, 0b11111111);

	// Инициализировать IDT
	idt_init();
	
	// Записать ISR PIT в IDT и инициализировать PIT
	init_pit();
	idt_set_entry(0x20, &pit_irq_handler, 0x8E);

	// Инициализировать KBC
	{
		u8 init_result = kbc_init();
		if (init_result != 0) {
			printf(&con, "I8084 PS/2 controller initialization failed");
			vga_flush_buffer();
			vga_update_cursor(&con);
			return 0;
		}
	}

	// Записать ISR клавиатуры в IDT и инициализировать клавиатуру 
	{	
		u8 init_result = kbrd_init();
		if (init_result == 1) {
			printf(&con, "PS/2 Keyboard initialization failed: Self-test failed");
			vga_flush_buffer();
			vga_update_cursor(&con);
			return 0;
		} else if (init_result == 2) {
			printf(&con, "PS/2 Keyboard initialization failed: Timeout");
			vga_flush_buffer();
			vga_update_cursor(&con);
			return 0;
		}
	}
	idt_set_entry(0x21, &kbrd_irq_handler, 0x8E);

	// Включить прерывания
	__asm__ volatile ("sti");

	// Проверить существует ли карта памяти
	{
		bool memory_map_valid = false;

		// Если хотя бы одна запись правильная, карта памяти существует
		for (u32 i = 0; i < 128; i++) {
			// Получить запись из карты
			memory_map_entry_t entry = memory_map[i];
			
			if (entry.type > 0 && entry.type < 4) {
				memory_map_valid = true;
				break;
			}
		}

		// Вывести сообщение если карта не существует
		if (!memory_map_valid) {
			printf(&con, "Memory map invalid (your BIOS does not support E820 maps)");
			vga_flush_buffer();
			vga_update_cursor(&con);
			return 0;
		}
	}

	// Инициализировать PMM
	pmm_init(memory_map);

	{
		u64 ram = 0;
		for (u32 i = 0; i < 128; i++) {
			// Получить запись из карты
			memory_map_entry_t entry = memory_map[i];

			// Если запись соответствует свободному участку памяти освободить этот участок в битмапе
			if (entry.type == 1) {
				ram += entry.length;
			}
		}

		printf(&con, "%d\r\n", (u32)(ram / 1024));
		vga_flush_buffer();
		vga_update_cursor(&con);
	}

	for (u32 i = 0; ; i++) {
		(void)kbrd_read_scancode();
		printf(&con, "Scancode %h\r\n", kbrd_wait_scancode());
		vga_flush_buffer();
		vga_update_cursor(&con);
	}
	
	return 0;
}