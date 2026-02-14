#include "ports.h"
#include "cmos.h"

#define CMOS_SELECT 0x70
#define CMOS_DATA 0x71

#define CMOS_RTC_SECOND 0x00
#define CMOS_RTC_MINUTE 0x02
#define CMOS_RTC_HOUR 0x04
#define CMOS_RTC_DAY 0x07
#define CMOS_RTC_MONTH 0x08
#define CMOS_RTC_YEAR 0x09

#define CMOS_FLOPPY 0x10

#define CMOS_STATUS_A 0x0A
#define CMOS_STATUS_B 0x0B
#define CMOS_STATUS_C 0x0C

// Записать регистр CMOS
static void cmos_write(u8 reg, u8 val) {
	outb(CMOS_SELECT, (1 << 7) | reg);
	io_wait();
	outb(CMOS_DATA, val);
}

// Прочитать регистр CMOS
static u8 cmos_read(u8 reg) {
	outb(CMOS_SELECT, (1 << 7) | reg);
	io_wait();
	return inb(CMOS_DATA);
}

// Проверить находится ли RTC в состоянии UIP
static u8 rtc_get_update_in_progress() {
	return cmos_read(CMOS_STATUS_A) & 0x80; // Бит 7 регистра статуса A
}

// Прочитать CMOS RTC
rtc_time_t cmos_read_rtc() {
	// Подождать пока RTC закончит обновление
	while (rtc_get_update_in_progress());

	// Выключить прерывания
	__asm__ volatile ("cli");

	// Прочитать регистры
	rtc_time_t time;
	time.second	= cmos_read(CMOS_RTC_SECOND);
	time.minute	= cmos_read(CMOS_RTC_MINUTE);
	time.hour	= cmos_read(CMOS_RTC_HOUR);
	time.day	= cmos_read(CMOS_RTC_DAY);
	time.month	= cmos_read(CMOS_RTC_MONTH);
	time.year	= cmos_read(CMOS_RTC_YEAR);

	// Включить прерывания
	__asm__ volatile ("sti");

	return time;
}

// Прочитать CMOS флоппи информацию
cmos_floppy_t cmos_read_floppy(bool slave) {
	// Прочитать данные
	u8 data = cmos_read(CMOS_FLOPPY);

	// Биты 0-3 Slave привод биты 4-7 Master привод
	if (slave) {
		return data & 0b00001111;
	} else {
		return (data >> 4) & 0b00001111;
	}
}