#include "types.h"
#include "ports.h"
#include "dma.h"

// Регистры
#define SARC_BASE		0x00
#define CRC_BASE		0x01
#define STATUS			0x08
#define CMD				0x08
#define REQUEST			0x09
#define SCMR			0x0A
#define MODE			0x0B
#define FLIP_FLOP		0x0C
#define INTERMEDIATE	0x0D
#define RESET			0x0D
#define MASK			0x0E
#define MULTI_MASK		0x0F
#define CH0_PAGE		0x80
#define CH1_PAGE		0x83
#define CH2_PAGE		0x81
#define CH3_PAGE		0x82

// Замаскировать канал
static void mask(dma_channel_t channel) {
	outb(MASK, channel | 0b00000100);
}

// Размаскировавть канал
static void unmask(dma_channel_t channel) {
	outb(MASK, channel);
}

// Инициализировать DMA канал
void dma_init(dma_channel_t channel, u32 address, u16 count) {
	// Регистры
	u16 sarc = channel * 2 + SARC_BASE;
	u16 crc = channel * 2 + CRC_BASE;
	u16 page;
	switch (channel) {
		case DMA_CHANNEL_0:
			page = CH0_PAGE;
			break;
		case DMA_CHANNEL_1:
			page = CH1_PAGE;
			break;
		case DMA_CHANNEL_2:
			page = CH2_PAGE;
			break;
		case DMA_CHANNEL_3:
			page = CH3_PAGE;
			break;
		default:
			page = CH0_PAGE;
			break;
	}

	// Замаскировать канал
	mask(channel);

	// Сбросить флип флоп
	outb(FLIP_FLOP, 0);

	// Нижний байт адреса
	outb(sarc, address & 0xFF);
	
	// Верхний байт адреса
	outb(sarc, (address >> 8) & 0xFF);

	// Сбросить флип флоп
	outb(FLIP_FLOP, 0);

	// Нижний байт длины
	outb(crc, count & 0xFF);
	
	// Верхний байт длины
	outb(crc, (count >> 8) & 0xFF);

	// Страница (третий байт адреса)
	outb(page, (address >> 16) & 0xFF);
	
	// Размаскировать канал
	unmask(channel);
}

// Подготовить DMA канал
void dma_prepare(dma_channel_t channel, u8 mode) {
	// Замаскировать канал
	mask(channel);
	
	// Режим
	outb(MODE, mode);
	
	// Размаскировать канал
	unmask(channel);
}