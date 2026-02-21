#include "vga.h"
#include "idt.h"
#include "keyboard.h"
#include "print.h"
#include "types.h"

// IDT запись
typedef struct {
	u16	isr_low;		// Нижние 16 бит адреса ISR
	u16	code_segment;	// Селектор сегмента GDT для кода
	u8	reserved;		// Зарезервировано
	u8	flags;			// Флаги
	u16	isr_high;		// Верхние 16 бит адреса ISR
} __attribute__((packed)) idt_entry_t;

// IDT с 256 записями
__attribute__((aligned(0x10))) 
static idt_entry_t idt[256];

// Дескриптор IDT
typedef struct {
	u16 limit;	// Длина
	i64 base;	// Адрес
} __attribute__((packed)) idtr_t;

// Дескриптор IDT
static idtr_t idtr;

// Установить запись IDT
void idt_set_entry(u8 vector, void* isr, u8 flags) {
	// Позучить указатель на запись
	idt_entry_t* entry = &idt[vector];

	entry->isr_low		= (u32)isr & 0xFFFF;	// Нижние 16 бит адреса ISR
	entry->code_segment	= 0x08;					// GDT селектор кода
	entry->flags		= flags;				// Флаги
	entry->isr_high		= (u32)isr >> 16;		// Верхние 16 бит адреса ISR
	entry->reserved		= 0;					// Зарезервировано
}

// Пустой ISR
__attribute__((interrupt))
static void dummy_handler(interrupt_frame_t* frame) {
	(void)frame;
}

// ISR #GP исключения
__attribute__((interrupt, noreturn))
static void gpf_handler(interrupt_frame_t* frame, u32 error_code) {
	// Создать объект консоли
	console_t con;
	con.x = 0;
	con.y = 0;
	con.attr = VGA_BLUE << 4 | VGA_WHITE;

	// Очистить экран
	vga_clear(&con);

	// Вывести сообщение
	printf(&con, 
		"PANIC! #GP Exception\r\n"
		"      _~^~^~_\r\n"
		"  \\) /  o o  \\ (/\r\n"
		"     '_  \x7F  _'\r\n"
		"    / '-----' \\\r\n"
		"Error code %h: ",
	error_code);

	// Обработать код ошибки
	if (error_code & 0b00000001) printf(&con, "External ");
	printf(&con, "Table %d ", error_code >> 1 & 0b00000011);
	printf(&con, "Index %d\r\n", error_code >> 3);
	
	// Вывести регистры из фрейма прерывания
	printf(&con,
		"EIP    %h\r\n"
		"EFLAGS %h\r\n"
		"CS     %h\r\n",
	frame->eip, frame->eflags, frame->cs);
	
	// Отобразить
	vga_flush_buffer();

	// Бесконечный цикл
	__asm__ volatile ("cli");
	__asm__ volatile ("hlt");
}

// ISR Breakpoint исключения
__attribute__((interrupt))
static void breakpoint_handler(interrupt_frame_t* frame) {
	// Создать консоль
	console_t con;
	con.x = 0;
	con.y = 0;
	con.attr = VGA_GREEN << 4 | VGA_WHITE;

	// Очистить экран
	vga_clear(&con);
	
	// Вывести сообщение
	printf(&con, 
		"Breakpoint exception\r\n"
		"      _~^~^~_\r\n"
		"  \\) /  o o  \\ (/\r\n"
		"     '_  -  _'\r\n"
		"    / '-----' \\\r\n"
		"Press any key to continue\r\n"
	);

	// Вывести регистры из фрейма прерывания
	printf(&con,
		"EIP    %h\r\n"
		"EFLAGS %h\r\n"
		"CS     %h",
	frame->eip, frame->eflags, frame->cs);
	vga_flush_buffer();

	// Подождать нажатия клавиши
	__asm__ volatile ("sti");
	(void)kbrd_read_scancode();
	(void)kbrd_wait_scancode();
}

// Инициализировать IDT
void idt_init() {
	idtr.base =	(i64)&idt[0];
	idtr.limit = (u16)sizeof(idt_entry_t) * 256 - 1;

	// Заполнить все записи пустыми ISR
	for (u8 vector = 0;; vector++) {
		idt_set_entry(vector, &dummy_handler, 0x8E);
		if (vector == 255) break;
	}

	// #GP ISR
	idt_set_entry(0x0D, &gpf_handler, 0x8E);

	// Breakpoint ISR
	idt_set_entry(0x03, &breakpoint_handler, 0x8E);

	// Загрузить IDT
	__asm__ volatile ("lidt %0" : : "m"(idtr));
}