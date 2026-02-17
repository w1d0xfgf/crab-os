#include "types.h"

#ifndef KBC_H
#define KBC_H

#define KBC_DATA 0x60
#define KBC_CMD 0x64
#define KBC_CONFIG_READ_CMD 0x20
#define KBC_CONFIG_WRITE_CMD 0x60

u8 kbc_send_cmd(u8 cmd);
u8 kbc_read_data();
u8 kbc_write_data(u8 data);
u8 kbc_init();
void kbc_cpu_reset();

#endif