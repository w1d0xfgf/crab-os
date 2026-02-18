#include "pic.h"
#include "idt.h"
#include "ports.h"
#include "pit.h"

#define CH_BASE 0x40
#define MODE_REG 0x43

// Тики PIT
static volatile u32 pit_ticks = 0;

// Хендлер IRQ PIT
__attribute__((interrupt("IRQ")))
void pit_irq_handler(interrupt_frame_t* frame) {
	(void)frame;

	// Увеличить тики PIT
	pit_ticks++;

	// Отправить EOI PIC
	pic_send_eoi(0);
}

// Запрограммировать PIT
void pit_program(u8 mode, u32 frequency) {
	// Режим
	outb(MODE_REG, mode);

	// Посчитать делитель и вывести его через порты
	u16 div = 1193182 / frequency;
	u8 channel = mode >> 6 & 0b00000011;
	outb(CH_BASE + channel, (u8)div);
	outb(CH_BASE + channel, (u8)(div >> 8));
}

// Получить тики PIT
u32 get_pit_ticks() {
	return pit_ticks;
}

// Подождать определённое количество тиков
void pit_sleep_ticks(u32 ticks) {
	u32 target_ticks = pit_ticks + ticks;
	while (pit_ticks < target_ticks) {
		// Подождать прерывания
		__asm__ volatile ("hlt");
	}
}