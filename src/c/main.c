#include "vga.h"
#include "idt.h"
#include "types.h"
#include "kbc.h"
#include "speaker.h"
#include "keyboard.h"
#include "pic.h"
#include "pit.h"
#include "print.h"
#include "cmos.h"
#include "pmm.h"
#include "mouse.h"
#include "utils.h"
#include "serial.h"
#include "shell.h"

// Напечатать предупреждение
void warn(console_t* con2, char* msg) {
	console_t con;
	con.x = con2->x;
	con.y = con2->y;
	con.attr = VGA_YELLOW;
	printf(&con, "WARNING: %s\r\n", msg);
	con2->x = con.x;
	con2->y = con.y;
	vga_flush_buffer();
	vga_update_cursor(con2);
}

// Напечатать ошибку и зависнуть
void error(console_t* con2, char* msg) {
	console_t con;
	con.x = con2->x;
	con.y = con2->y;
	con.attr = VGA_RED;
	printf(&con, "ERROR: %s\r\n", msg);
	con2->x = con.x;
	con2->y = con.y;
	vga_flush_buffer();
	vga_update_cursor(con2);
	for (;;);
}

u32 kmain(memory_map_entry_t* memory_map) {
	// Инициализировать VGA
	console_t con;
	con.x = 0;
	con.y = 0;
	con.attr = VGA_WHITE;
	vga_clear(&con);
	vga_disable_blink();
	vga_set_cursor(12, 14);
	vga_flush_buffer();
	vga_update_cursor(&con);

	// Инициализировать COM порт
	if (serial_init(serial_get_base(0)) == 0) {
		serial_print(serial_get_base(0), "COM1 port test");
	} else {
		warn(&con, "COM1 port initialization failed");
	}

	// Инициализировать PIC с размаскированным IRQ0, IRQ1, IRQ2, IRQ12
	pic_init(0b11111000, 0b11101111);

	// Инициализировать IDT
	idt_init();
	
	// Записать ISR PIT в IDT и запрограммировать канал 0 PIT на 10000 Гц
	pit_program(0b00110100, 10000);
	idt_set_entry(0x20, &pit_irq_handler, 0x8E);
	
	// Инициализировать KBC
	u8 kbc_dual;
	{
		u8 init_result = kbc_init();

		// Проверить была ли инициализация успешна
		switch (init_result) {	
			case 2:
				warn(&con, "I8042 PS/2 Controller initialization failed: Self-test failed");
				break;
			case 3:
				warn(&con, "I8042 PS/2 Controller initialization failed: Interface tests failed");
				break;
			default:
				kbc_dual = init_result;
				break;
		}
	}

	// Записать ISR клавиатуры в IDT и инициализировать клавиатуру 
	{
		// Проверить была ли инициализация успешна
		switch (kbrd_init()) {	
			case 1:
				kbc_disable_port1();
				warn(&con, "PS/2 Keyboard initialization failed: Self-test failed");
				break;
			case 2:
				kbc_disable_port1();
				warn(&con, "PS/2 Keyboard initialization failed: Timeout");
				break;
			default:
				break;
		}
	}
	idt_set_entry(0x21, &kbrd_irq_handler, 0x8E);

	// Если у KBC есть порт мышки
	if (kbc_dual) {
		// Инициализировать мышку
		switch (mouse_init()) {	
			case 1:
				kbc_disable_port2();
				warn(&con, "PS/2 Mouse initialization failed: Self-test failed");
				break;
			case 2:
				kbc_disable_port2();
				warn(&con, "PS/2 Mouse initialization failed: Timeout");
				break;
			default:
				break;
		}
		
		// Записать ISR мышки в IDT
		idt_set_entry(0x2C, &mouse_irq_handler, 0x8E);
	}

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

		// Выдать ошибку если карта не существует
		if (!memory_map_valid) error(&con, "Memory map invalid (your BIOS does not support E820 maps)");
	}

	// Инициализировать PMM
	pmm_init(memory_map);
	pmm_reserve(0x8200, 50000);
	pmm_reserve(0xA0000, 0x20000);

	// Терминал
	shell_main(&con);
	
	return 0;
}