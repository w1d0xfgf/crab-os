#include "types.h"

#ifndef DMA_H
#define DMA_H

typedef enum {
	DMA_CHANNEL_0 = 0,
	DMA_CHANNEL_1 = 1,
	DMA_CHANNEL_2 = 2,
	DMA_CHANNEL_3 = 3
} dma_channel_t;

void dma_init(dma_channel_t channel, u32 address, u16 count);
void dma_prepare(dma_channel_t channel, u8 mode);

#endif