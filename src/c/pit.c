#include "pit.h"
#include "pic.h"
#include "idt.h"
#include "ports.h"

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

// Инициализировать PIT
void init_pit() {
	// Настроить PIT
	outb(0x43, 0b00110100);

	// Посчитать делитель и вывести его через порты
	u16 div = 1193182 / PIT_FREQUENCY;
	outb(0x40, (u8)div);
	outb(0x40, (u8)(div >> 8));
}

// Получить тики PIT
u64 get_pit_ticks() {
	return pit_ticks;
}

// Подождать определённое количество тиков
void pit_sleep_ticks(u8 ticks) {
	u64 target_ticks = pit_ticks + ticks;
	while (pit_ticks < target_ticks) {
		// Подождать прерывания
		__asm__ volatile ("hlt");
	}
}