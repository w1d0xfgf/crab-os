#include "pic.h"
#include "idt.h"
#include "ports.h"
#include "types.h"
#include "keyboard.h"

// Был ли последний сканкод 0xE0?
static bool last_e0 = false;

// Полный последний сканкод
static u16 last_scancode = 0;

// Нажатые клавиши
static bool pressed_keys[255] = {false};

// Хендлер IRQ клавиатуры
__attribute__((interrupt("IRQ")))
void kbrd_irq_handler(interrupt_frame_t* frame) {
	(void)frame;

	// Получить данные от KBC
	u8 data = inb(KBC_DATA);

	// Если данные 0xE0 (префикс расширенных клавиш), поставить флаг
	if (data == 0xE0) {
		last_e0 = true;
	} 
	// Если данные не 0xE0 сохранить весь сканкод
	else {
		// Уникальные индексы для обычных и расширенных клавиш (только Make)
		u8 idx = data & ~(0x80);
		if (last_e0) idx |= 0x80;

		// Проверить является ли сканкод Make или Break
		if (data & 0x80) {
			pressed_keys[idx] = false;
		} else {
			pressed_keys[idx] = true;
		}

		// Сохранить сканкод
		if (last_e0) {
			last_scancode = (0xE0 << 8) | data;
		} else {
			last_scancode = data;
		}

		// Сбросить флаг
		last_e0 = false;
	}

	// Отправить EOI PIC
	pic_send_eoi(1);
}

// Получить последний сканкод
u16 kbrd_get_last_scancode() {
	return last_scancode;
}

// Получить нажатие клавиши
u8 kbrd_get_key_pressed(u8 idx) {
	return pressed_keys[idx];
}