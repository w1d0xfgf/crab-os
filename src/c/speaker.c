#include "pit.h"
#include "ports.h"
#include "speaker.h"

// Установить частоту
void spkr_set_frequency(u32 frequency) {
	// Запрограммировать канал 2 PIT
	pit_program(0b10110110, frequency);
}

// Включить
void spkr_on() {
	u8 control = inb(0x61);
	outb(0x61, control | 0b00000011);
}

// Выключить
void spkr_off() {
	u8 control = inb(0x61);
	outb(0x61, control & 0b11111100);
}