#include "vga.h"
#include "idt.h"
#include "types.h"
#include "keyboard.h"
#include "pic.h"
#include "pit.h"
#include "print.h"
#include "cmos.h"
#include "utils.h"

typedef struct {
	u64 base;
	u64 length;
	u32 type;
	u32 reserved;
} __attribute__((packed)) memory_map_entry_t;

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

	// Сделать структуру консоли для вывода на экран
	console_t con;
	con.x = 0;
	con.y = 0;
	con.attr = VGA_LIGHT_GREEN;

	// Цикл
	for (;;) {
		// Строка 0 цвет зелёный
		con.x = 0;
		con.y = 0;
		con.attr = VGA_LIGHT_GREEN;

		// Очистить экран и напечатать "Hello kernel!"
		vga_clear(&con);
		printf(&con, "Hello kernel!");

		// Строка 1 цвет белый
		con.x = 0;
		con.y = 1;
		con.attr = VGA_WHITE;

		// PIT тики
		printf(&con, "Time since bootup: %d s %d ms",
			(u32)get_pit_ticks() / PIT_FREQUENCY,
			(u32)get_pit_ticks() * 1000 / PIT_FREQUENCY % 1000
		);

		// Строка 2
		con.x = 0;
		con.y = 2;

		// Прочитать RTC
		rtc_time_t time = cmos_read_rtc();

		// HH:MM:SS
		printf(&con, "%b:%b:%b", time.hour, time.minute, time.second);

		// Строка 3
		con.x = 0;
		con.y = 3;

		// DD/MM/YY
		printf(&con, "%b/%b/%b", time.day, time.month, time.year);

		// Строка 4
		con.x = 0;
		con.y = 4;

		kbrd_get_key_pressed(0x01) ? printf(&con, "#") : printf(&con, "-");

		// Отобразить
		vga_flush_buffer();
	}

	return 0;
}