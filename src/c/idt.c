#include "vga.h"
#include "idt.h"
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

// #GP ISR
__attribute__((interrupt, noreturn))
static void gpf_handler(interrupt_frame_t* frame, u32 error_code) {
	(void)frame;
	(void)error_code;
	u8 str[] = "#GP Exception";
	for (u8* ptr = (u8*)(0xB8000); ptr < 0xB8000 + 80 * 25 * 2; ptr++) {
		*ptr = ' ';
		ptr++;
		*ptr = 0x07;
	}
	for (int i = 0; i < sizeof(str) / sizeof(u8); i++) {
		*(u8*)(0xB8000 + i * 2) = str[i];
		*(u8*)(0xB8001 + i * 2) = 0x07;
	}
	for (;;) {}
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

	// Загрузить IDT
	__asm__ volatile ("lidt %0" : : "m"(idtr));
}