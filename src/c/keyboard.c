#include "pic.h"
#include "idt.h"
#include "types.h"
#include "kbc.h"
#include "ports.h"
#include "keyboard.h"

typedef struct {
	u16 buf[32];
	u32 read;
	u32 write;
} keyboard_buffer_t;

// FIFO буфер Make сканкодов
static volatile keyboard_buffer_t buffer = {
	.buf = {0},
	.read = 0,
	.write = 0
};

// Был ли последний сканкод 0xE0?
static bool last_e0 = false;

// Нажатые клавиши
static bool pressed_keys[256] = {false};

// Сохранить сканкод в буфер
static void save_to_buffer(u16 scancode) {
	buffer.buf[buffer.write] = scancode;
	buffer.write = (buffer.write + 1) % 32;
}

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
		// Уникальные индексы для обычных и расширенных Make сканкодов
		u8 idx = data & ~(0x80);
		if (last_e0) idx |= 0x80;

		// Обновить таблицу
		if (data & 0x80) {
			// Break
			pressed_keys[idx] = false;
		} else {
			// Make
			pressed_keys[idx] = true;
		}

		// Сохранить сканкод
		if (!(data & 0x80)) {
			u16 scancode;
			if (last_e0) {
				scancode = (0xE0 << 8) | data;
			} else {
				scancode = data;
			}
			save_to_buffer(scancode);
		}
		
		// Сбросить флаг
		last_e0 = false;
	}

	// Отправить EOI PIC
	pic_send_eoi(1);
}

// Инициализировать клавиатуру
u8 kbrd_init() {
	kbc_send_byte_port1(0xFF);
	u16 byte1 = kbc_read_data();
	u16 byte2 = kbc_read_data();

	if (byte1 == 0xFFFF || byte2 == 0xFFFF) return 2;
	if (byte1 == 0xFC) return 1;
	return 0;
}

// Получить сканкод
u16 kbrd_read_scancode() {
	if (buffer.read == buffer.write) return 0;
	u16 val = buffer.buf[buffer.read];
	buffer.read = (buffer.read + 1) % 32;
	return val;
}

// Подождать и получить сканкод
u16 kbrd_wait_scancode() {
	u16 scancode = 0;
	while (scancode == 0) {
		scancode = kbrd_read_scancode();
	}
	return scancode;
}

// Получить нажатие клавиши
u8 kbrd_get_key_pressed(u8 idx) {
	return pressed_keys[idx];
}