#include "types.h"

#ifndef CMOS_H
#define CMOS_H

typedef enum {
	NO_DRIVE = 0,
	KB_360__IN_5_25 = 1,
	MB_1_2__IN_5_25 = 2,
	KB_720__IN_3_5 = 3,
	MB_1_44__IN_3_5 = 4,
	MB_2_88__IN_3_5 = 5,
} cmos_floppy_t;

typedef struct {
	u8 second;
	u8 minute;
	u8 hour;
	u8 day;
	u8 month;
	u8 year;
} rtc_time_t;

rtc_time_t cmos_read_rtc();

#endif