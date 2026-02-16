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
	con.attr = VGA_WHITE;

	// Инициализировать VGA
	vga_disable_blink();
	vga_set_cursor(14, 16);
	vga_clear(&con);
	vga_flush_buffer();

	// Напечатать "Hello kernel!"
	printf(&con, "Hello kernel!\r\n");
	vga_flush_buffer();

	return 0;
}