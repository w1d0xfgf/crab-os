; ------------------------------------------------------------------
; Драйвер RTC (Real-Time Clock)
; ------------------------------------------------------------------

%define CMOS_ADDR 0x70
%define CMOS_DATA 0x71

; Регистры RTC
%define RTC_SECONDS 0x00
%define RTC_MINUTES 0x02
%define RTC_HOURS 0x04
%define RTC_DAYS 0x07
%define RTC_MONTHS 0x08
%define RTC_YEAR 0x09

; Чтение одного байта из CMOS
;
; Регистр: AL
read_cmos:
    out  CMOS_ADDR, al
    in   al, CMOS_DATA
    ret

; Проверка UIP (update in progress)
;
; Использует: AL
wait_rtc:
    mov al, 0x0A        ; Статус А
.check_uip:
    out CMOS_ADDR, al
    in al, CMOS_DATA
    test al, 0x80      	; Если UIP = 1, ожидание
    jnz .check_uip
    ret

; Получение времени
;
; Секунда: BL
; Минута: BH
; Час: CL
; День: CH
; Месяц: DL
; Год: DH
get_rtc_time:
	; Ожидание окончания обновления всех регистров
    call wait_rtc        
	
	; Секунда
    mov al, RTC_SECONDS
    call read_cmos
    mov bl, al           
    
	; Минута
    mov al, RTC_MINUTES
    call read_cmos
    mov bh, al
	
	; Час
    mov al, RTC_HOURS
    call read_cmos
    mov cl, al     

	; День
    mov al, RTC_DAYS
    call read_cmos
    mov ch, al  	
	
	; Месяц
    mov al, RTC_MONTHS
    call read_cmos
    mov dl, al 
	
	; Год
    mov al, RTC_YEAR
    call read_cmos
    mov dh, al 
	
    ret