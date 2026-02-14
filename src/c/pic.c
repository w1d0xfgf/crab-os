#include "pit.h"
#include "pic.h"
#include "types.h"
#include "ports.h"

// Remap смещения для Master и Slave PIC
#define PIC1_OFFSET		0x20
#define PIC2_OFFSET		0x28

// Порты Master и Slave PIC
#define PIC1_CMD		0x20
#define PIC1_DATA		0x21
#define PIC2_CMD		0xA0
#define PIC2_DATA		0xA1

// PIC EOI команда
#define PIC_EOI			0x20

// Для PIC Remap
#define ICW1_ICW4		0x01
#define ICW1_SINGLE		0x02
#define ICW1_INTERVAL4	0x04
#define ICW1_LEVEL		0x08
#define ICW1_INIT		0x10

#define ICW4_8086		0x01
#define ICW4_AUTO		0x02
#define ICW4_BUF_SLAVE	0x08
#define ICW4_BUF_MASTER	0x0C
#define ICW4_SFNM		0x10

#define CASCADE_IRQ 2

// Отправить EOI PIC
__attribute__((no_caller_saved_registers))
void pic_send_eoi(u8 irq) {
	// Если IRQ Slave PIC то нужно отправить Slave PIC EOI
	if(irq >= 8)
		__asm__ volatile ("outb %b0, %w1" : : "a"(PIC_EOI), "Nd"(PIC2_CMD) : "memory");
	
	// Отправить Master PIC EOI
	__asm__ volatile ("outb %b0, %w1" : : "a"(PIC_EOI), "Nd"(PIC1_CMD) : "memory");
}

// Remap PIC
void pic_init(u8 mask1, u8 mask2) {
	// ICW1: Инициализация
	outb(PIC1_CMD, ICW1_INIT | ICW1_ICW4);
	io_wait();
	outb(PIC2_CMD, ICW1_INIT | ICW1_ICW4);
	io_wait();

	// ICW2: Смещения
	outb(PIC1_DATA, PIC1_OFFSET);
	io_wait();
	outb(PIC2_DATA, PIC2_OFFSET);
	io_wait();

	// ICW3: Соединения
	outb(PIC1_DATA, 1 << CASCADE_IRQ);
	io_wait();
	outb(PIC2_DATA, 2);
	io_wait();
	
	// ICW4: Режим 8086
	outb(PIC1_DATA, ICW4_8086);
	io_wait();
	outb(PIC2_DATA, ICW4_8086);
	io_wait();

	// Установить маски Master и Slave PIC
	outb(PIC1_DATA, mask1);
	outb(PIC2_DATA, mask2);
}