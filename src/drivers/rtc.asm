; ------------------------------------------------------------------
; Драйвер Real Time Clock
; ------------------------------------------------------------------

; Порты CMOS
CMOS_ADDR equ 0x70
CMOS_DATA equ 0x71

; Регистры RTC
RTC_SECONDS equ 0x00
RTC_MINUTES equ 0x02
RTC_HOURS equ 0x04
RTC_DAYS equ 0x07
RTC_MONTHS equ 0x08
RTC_YEAR equ 0x09

; ------------------------------------------------------------------

; Получить временя и дату
;
; Секунда: BL
; Минута: BH
; Час: CL
; День: CH
; Месяц: DL
; Год: DH
; Меняет: AL
get_rtc_time:
	; Ожидание окончания обновления всех регистров
	call .wait_rtc
	
	; Секунда
	mov al, RTC_SECONDS
	call .read_cmos
	mov bl, al
	
	; Минута
	mov al, RTC_MINUTES
	call .read_cmos
	mov bh, al
	
	; Час
	mov al, RTC_HOURS
	call .read_cmos
	mov cl, al

	; День
	mov al, RTC_DAYS
	call .read_cmos
	mov ch, al
	
	; Месяц
	mov al, RTC_MONTHS
	call .read_cmos
	mov dl, al
	
	; Год
	mov al, RTC_YEAR
	call .read_cmos
	mov dh, al
	
	ret
.read_cmos:
	out CMOS_ADDR, al
	in al, CMOS_DATA
	ret
.wait_rtc:
	mov al, 0x0A
.check_uip:
	out CMOS_ADDR, al
	in al, CMOS_DATA
	test al, 0x80
	jnz .check_uip

	ret