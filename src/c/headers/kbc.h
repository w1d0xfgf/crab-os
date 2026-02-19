#include "types.h"

#ifndef KBC_H
#define KBC_H

#define KBC_DATA 0x60
#define KBC_CMD 0x64
#define KBC_CONFIG_READ_CMD 0x20
#define KBC_CONFIG_WRITE_CMD 0x60

#define KBC_ACK 0xFA

u8 kbc_read_data();
u8 kbc_init();
void kbc_send_byte_port1(u8 byte);
void kbc_send_byte_port2(u8 byte);
void kbc_disable_port1();
void kbc_disable_port2();
void kbc_cpu_reset();

#endif