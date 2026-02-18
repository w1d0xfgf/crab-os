#include "types.h"
#include "ports.h"
#include "kbc.h"

// Прочитать статус KBC
static u8 kbc_read_status() {
	// Данные из порта команд это статус
	return inb(KBC_CMD);
}

// Отправить команду KBC
u8 kbc_send_cmd(u8 cmd) {
	// Подождать пока входной буфер контроллера будет пустым
	for (u32 i = 0; i < 1000000; i++) {
		if (!(kbc_read_status() & 0b00000010)) {
			// Отправить команду
			outb(KBC_CMD, cmd);
			return 0;
		}
	}
	return 1;
}

// Прочитать данные из KBC
u8 kbc_read_data() {
	// Подождать пока выходной буфер контроллера будет полным
	for (u32 i = 0; i < 1000000; i++) {
		if (kbc_read_status() & 0b00000001) {
			// Получить данные
			return inb(KBC_DATA);
		}
	}
	return -1;
}

// Записать данные в KBC
u8 kbc_write_data(u8 data) {
	// Подождать пока входной буфер контроллера будет пустым
	for (u32 i = 0; i < 1000000; i++) {
		if (!(kbc_read_status() & 0b00000010)) {
			// Отправить данные
			outb(KBC_DATA, data);
			return 0;
		}
	}
	return 1;
}

// Прочитать конфигурацию KBC
static u8 kbc_read_config() {
	kbc_send_cmd(KBC_CONFIG_READ_CMD);
	return kbc_read_data();
}

// Записать конфигурацию KBC
static void kbc_write_config(u8 val) {
	kbc_send_cmd(KBC_CONFIG_WRITE_CMD);
	(volatile void)kbc_write_data(val);
}

// Инициализировать KBC
u8 kbc_init() {
	// Выключить порты
	kbc_send_cmd(0xAD);
	kbc_send_cmd(0xA7);

	// Очистить буфер
	(void)inb(KBC_DATA);
	(void)inb(KBC_DATA);
	(void)inb(KBC_DATA);

	// Установить конфигурацию
	{
		u8 config = kbc_read_config();
		config |= 0b01000001;
		config &= 0b11001101;
		kbc_write_config(config);
	}

	// Self-Test контроллера
	kbc_send_cmd(0xAA);
	if (kbc_read_data() != 0x55) return 1;

	// Заного установить конфигурацию
	{
		u8 config = kbc_read_config();
		config |= 0b01000001;
		config &= 0b11001101;
		kbc_write_config(config);
	}

	// Проверить 2 порта или нет
	bool dual = false;
	{
		// Включить порт 2
		kbc_send_cmd(0xA8);

		// Если в конфигурации он включён значит он есть
		u8 config = kbc_read_config();
		if (!(config & 0b00100000)) dual = true;

		// Выключить его
		kbc_send_cmd(0xA7);
	}

	// Тест порта 1
	kbc_send_cmd(0xAB);
	if (kbc_read_data() != 0) return 2;

	// Тест порта 2
	if (dual) {
		kbc_send_cmd(0xA9);
		if (kbc_read_data() != 0) return 3;
	}

	// Включить порты
	kbc_send_cmd(0xAE);
	kbc_send_cmd(0xA8);

	return 0;
}

// Сброс с помощью KBC
void kbc_cpu_reset() {
	kbc_send_cmd(0xFE);
}