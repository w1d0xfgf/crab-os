#include "kbc.h"
#include "idt.h"
#include "pic.h"
#include "types.h"
#include "kbc.h"
#include "ports.h"
#include "mouse.h"

// Пакет мышки
typedef struct {
	u8 byte1, byte2, byte3;
	u32 idx;
} mouse_packet_t;

// Состояние мышки
static mouse_state_t mouse_state = {
	.dx = 0,
	.dy = 0,
	.lmb = false,
	.rmb = false,
	.mmb = false,
};

// Пакет мышки
static mouse_packet_t packet = {
	.byte1 = 0,
	.byte2 = 0,
	.byte3 = 0,
	.idx = 0
};

// Lock для избежания записи во время чтения
static volatile bool lock = false;

// Отправить один байт мышке
u8 send_byte(u8 byte) {
	// Байт
	kbc_send_byte_port2(byte);

	// ACK
	u8 ack = kbc_read_data();
	if (ack != KBC_ACK) return 1;

	return 0;
}

// Хендлер IRQ мышки
__attribute__((interrupt("IRQ")))
void mouse_irq_handler(interrupt_frame_t* frame) {
	(void)frame;
	
	// Убедится то что есть данные
	if (!(inb(0x64) & 0b00000001)) {
		pic_send_eoi(12);
		return;
	};

	// Получить данные
	u8 data = inb(KBC_DATA);

	// Lock
	if (lock) {
		pic_send_eoi(12);
		return;
	}

	// Записать байт
	switch (packet.idx) {
		case 0:
			packet.byte1 = data;
			break;
		case 1:
			packet.byte2 = data;
			break;
		case 2:
			packet.byte3 = data;
			break;
		default:
			break;
	}

	// Увеличить индекс
	packet.idx++;

	// Обработать весь пакет
	if (packet.idx > 2) {		
		// Обновить состояние мышки, если не было Overflow DX или DY
		if (!(packet.byte1 & 0b10000000) && !(packet.byte1 & 0b01000000)) {
			// DX и DY
			i8 dx = packet.byte2;
			i8 dy = packet.byte3;
			mouse_state.dx += dx;
			mouse_state.dy += dy;

			// Кнопки
			mouse_state.lmb = packet.byte1 & 0b00000001;
			mouse_state.rmb = packet.byte1 & 0b00000010;
			mouse_state.mmb = packet.byte1 & 0b00000100;
		}

		// Сбросить индекс
		packet.idx = 0;
	}

	// Отправить EOI PIC
	pic_send_eoi(12);
}

// Инициализировать мышку
u8 mouse_init() {
	// Сбросить мышь
	u8 id;
	{
		// Команда сброса
		if (send_byte(0xFF)) return 1;

		// Self-Test
		u8 result = kbc_read_data();
		if (result != 0xAA) return 1;

		// ID
		id = kbc_read_data();
	}

	// Resolution: 2/мм
	if (send_byte(0xE8)) return 1;
	if (send_byte(2)) return 1;
	
	// Sample rate: 60 раз/с
	if (send_byte(0xF3)) return 1;
	if (send_byte(60)) return 1;

	// Включить отправку пакетов
	if (send_byte(0xF4)) return 1;

	return 0;
}

// Получить состояние мышки
mouse_state_t mouse_get_state() {
	// Lock
	lock = true;

	// Состояние
	mouse_state_t ret = mouse_state;

	// Lock
	lock = false;

	// Сбросить DX и DY
	mouse_state.dx = 0;
	mouse_state.dy = 0;

	return ret;
}