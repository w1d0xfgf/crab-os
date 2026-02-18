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

int kmain(memory_map_entry_t* memory_map) {
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
		// Проверить была ли инициализация успешна
		u8 init_result = kbc_init();
		if (init_result > 1) {
			printf(&con, "I8042 PS/2 controller initialization failed: ");
			if (init_result == 2) {
				printf(&con, "Self-test failed");
			} else if (init_result == 3) {
				printf(&con, "Interface tests failed");
			}
			
			vga_flush_buffer();
			vga_update_cursor(&con);
			return 0;
		} else {
			kbc_dual = init_result;
		}
	}

	// Записать ISR клавиатуры в IDT и инициализировать клавиатуру 
	{
		// Проверить была ли инициализация успешна
		u8 init_result = kbrd_init();
		if (init_result != 0) {
			printf(&con, "PS/2 Keyboard initialization failed: ");
			if (init_result == 1) {
				printf(&con, "Self-test failed");
			} else if (init_result == 2) {
				printf(&con, "Timeout");
			}
			
			vga_flush_buffer();
			vga_update_cursor(&con);
			return 0;
		}
	}
	idt_set_entry(0x21, &kbrd_irq_handler, 0x8E);

	// Если у KBC есть порт мышки
	if (kbc_dual) {
		// Записать ISR мышки в IDT и инициализировать мышку
		{
			// Проверить была ли инициализация успешна
			u8 init_result = mouse_init();
			if (init_result != 0) {
				printf(&con, "PS/2 Mouse initialization failed: ");
				if (init_result == 1) {
					printf(&con, "Self-test failed");
				} else if (init_result == 2) {
					printf(&con, "Timeout");
				}
				
				vga_flush_buffer();
				vga_update_cursor(&con);
				return 0;
			}
		}
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

	// Подсчитать свободную ОЗУ
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

		printf(&con, "%d KB memory free\r\n", (u32)(ram / 1024));
		vga_flush_buffer();
		vga_update_cursor(&con);
	}

	if (kbc_dual) {
		printf(&con, "KBC is dual");
	} else {
		printf(&con, "KBC is not dual");
	}
	vga_flush_buffer();
	vga_update_cursor(&con);
	(void)kbrd_read_scancode();
	(void)kbrd_wait_scancode();

	i16 mouse_x = 400;
	i16 mouse_y = 200;
	bool spkr = false;
	u16 last_scancode = 0;
	spkr_set_frequency(1000);
	for (;;) {
		// Переключать PC Speaker после каждого нажатия клавиши
		u16 scancode = kbrd_read_scancode();
		if (scancode > 0) {
			last_scancode = scancode;
			spkr = !spkr;
			spkr ? spkr_on() : spkr_off();
		}

		vga_clear(&con);

		// Напечатать всякую информацию
		con.x = 0;
		con.y = 0;
		printf(&con, "%d PIT ticks", get_pit_ticks());

		con.x = 0;
		con.y = 1;
		rtc_time_t time = cmos_read_rtc();
		printf(&con, "Current time: %b:%b:%b", time.hour, time.minute, time.second);

		con.x = 0;
		con.y = 2;
		printf(&con, "Last scancode: %h", last_scancode);
		vga_update_cursor(&con);

		// Курсор мышки
		mouse_state_t state = mouse_get_state();
		mouse_x += state.dx;
		mouse_y -= state.dy;
		con.x = mouse_x / 10 % 80;
		con.y = mouse_y / 20 % 25;
		state.lmb ? printf(&con, "o") : printf(&con, "#");
		
		vga_flush_buffer();
	}
	
	return 0;
}