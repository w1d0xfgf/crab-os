; ------------------------------------------------------------------
; Драйвер Floppy Disk Controller
; ------------------------------------------------------------------

bits 32

extern sleep_ticks

global fdc_irq_handler
global fdc_init
global fdd_do_cyl
global fdd_motor_on
global fdd_motor_off

%include "src/const.asm"

; Порты регистров FDC
FDC_DOR equ 0x3F2
FDC_MSR equ 0x3F4
FDC_DATA equ 0x3F5
FDC_CCR equ 0x3F7

; Макрос для отправки данных через порты
%macro outb 2
	mov al, %1
	out %2, al
%endmacro

; ------------------------------------------------------------------

section .text

; Хендлер IRQ FDC
fdc_irq_handler:
	; Сохранить состояние
	pushad
	push ds
	push es

	; Установить сегменты
	mov ax, DATA_SEL
	mov es, ax
	mov ds, ax

	mov byte [fdc_irq_fired], 1
	
	; Отправить EOI Master PIC
	mov al, PIC_EOI
	out PIC1, al

	; Восстановить состояние
	pop es
	pop ds
	popad

	iretd

; ------------------------------------------------------------------

; Подождать IRQ от FDC
;
; Меняет: ECX
fdc_wait_irq:
	; Попытки
	mov ecx, 0xFFFFFF
.loop:
	; Проверить статус IRQ
	cmp byte [fdc_irq_fired], 1
	je .done

	; Повторить, если не осталось попыток завершить цикл
	dec ecx
	jz .error
	jmp .loop
.done:
	; Сбросить статус IRQ
	mov byte [fdc_irq_fired], 0
	clc
	ret
.error:
	stc
	ret

; ------------------------------------------------------------------

; Инициализировать DMA для FDC
;
; Меняет: AL
fdc_init_dma:
	outb 0x06, 0x0A		; Маскировать канал 2
	outb 0xFF, 0x0C		; Сбросить флип-флоп
	outb 0x00, 0x04		; Нижний байт адреса буфера
	outb 0x10, 0x04		; Верхний байт адреса буфера
	outb 0xFF, 0x0C		; Сбросить флип-флоп
	outb 0xFF, 0x05		; Нижний байт длины
	outb 0x23, 0x05		; Верхний байт длины, длина теперь 23 FF (длина одной дорожки на диске)
	outb 0x00, 0x81		; External Page Register, адрес теперь 00 10 00
	outb 0x02, 0x0A		; Размаскировать канал 2

	ret

; ------------------------------------------------------------------

; Переключить DMA для FDC в режим записи
;
; Меняет: AL
fdc_dma_wr:
	outb 0x06, 0x0A		; Замаскировать канал 2
	outb 0x5A, 0x0B		; Режим
	outb 0x02, 0x0A		; Размаскировать канал 2

	ret

; ------------------------------------------------------------------

; Переключить DMA для FDC в режим чтения
;
; Меняет: AL
fdc_dma_rd:
	outb 0x06, 0x0A		; Замаскировать канал 2
	outb 0x56, 0x0B		; Режим
	outb 0x02, 0x0A		; Размаскировать канал 2

	ret

; ------------------------------------------------------------------

; Записать данные в порт данных FDC
;
; Данные: BL
; Меняет: AL, DX, ECX
fdc_data_wr:
	; Попытки
	mov ecx, 0xFFFF
.loop:
	; Получить статус
	mov dx, FDC_MSR
	in al, dx

	; Проверить, можно ли записать
	and al, 0xC0
	cmp al, 0x80
	je .done

	; Повторить
	dec ecx
	jz .error
	jmp .loop
.done:
	; Записать
	mov dx, FDC_DATA
	mov al, bl
	out dx, al
	clc
	ret
.error:
	stc
	ret

; ------------------------------------------------------------------

; Прочитать данные из порта данных FDC
;
; Данные: AL
; Меняет: AL, DX, ECX
fdc_data_rd:	
	; Попытки
	mov ecx, 0xFFFF
.loop:
	; Получить статус
	mov dx, FDC_MSR
	in al, dx

	; Проверить, можно ли прочитать
	and al, 0xC0
	cmp al, 0xC0
	je .done

	; Повторить
	dec ecx
	jz .error
	jmp .loop
.done:
	; Прочитать
	mov dx, FDC_DATA
	in al, dx
	clc
	ret
.error:
	stc
	ret

; ------------------------------------------------------------------

; Включить мотор FDD
;
; Меняет: AL, EDX
fdd_motor_on:
	; Настроить DOR
	mov al, (1 << 4) | (1 << 3) | (1 << 2) | 0
	mov dx, FDC_DOR
	out dx, al

	; Подождать 500 мс
	mov edx, PIT_FREQ/1000*500
	pushad
	call sleep_ticks
	popad

	ret

; ------------------------------------------------------------------

; Выключить мотор FDD
;
; Меняет: AL, DX
fdd_motor_off:
	; Настроить DOR
	mov al, (0 << 4) | (1 << 3) | (1 << 2) | 0
	mov dx, FDC_DOR
	out dx, al

	; Записать обратно
	out dx, al

	ret

; ------------------------------------------------------------------

; Выполнить FDC команду Sense Interrupt
;
; ST0: BL
; CYL: BH
; Меняет: AL, ECX, DX
fdc_sense:
	; Команда
	mov bl, 0x08
	call fdc_data_wr

	; Данные
	call fdc_data_rd
	mov bl, al
	call fdc_data_rd
	mov bh, al

	ret

; ------------------------------------------------------------------

; Выполнить FDC команду Recalibrate
;
; Меняет: AL, BL, ECX, DX
fdc_recalibrate:
	; Попытки
	mov ecx, 10
.loop:
	dec ecx
	jz .error

	push ecx

	; Команда
	mov bl, 0x07
	call fdc_data_wr

	; Привод 0
	xor bl, bl
	call fdc_data_wr

	; Подождать IRQ
	call fdc_wait_irq

	; Sense Interrupt
	call fdc_sense

	pop ecx

	; Проверить была ли ошибка
	test bl, 0xC0
	jnz .loop

	; Проверить пришла ли головка к цилиндру 0
	test bh, bh
	jnz .loop

	clc
	ret
.error:
	stc
	ret

; ------------------------------------------------------------------

; Выполнить FDC команду Seek
;
; Номер головки: BL
; Цилиндр: BH
; Меняет: AL, BL, ECX, DX
fdc_seek:
	; Первый параметр Seek это (head << 2) | drive
	shl bl, 2

	; Попытки
	mov ecx, 10
.loop:
	dec ecx
	jz .error

	push ecx
	push bx
	push bx

	; Команда
	mov bl, 0x0F
	call fdc_data_wr

	; Номер головки
	pop bx
	call fdc_data_wr

	; Цилиндр
	mov bl, bh
	call fdc_data_wr

	; Подождать IRQ
	call fdc_wait_irq

	; Sense Interrupt
	call fdc_sense
	mov dx, bx

	pop ecx
	pop bx

	; Проверить была ли ошибка
	test dl, 0xC0
	jnz .loop

	; Проверить пришла ли головка к цилиндру
	cmp dh, bh
	jne .loop

	clc
	ret
.error:
	stc
	ret

; ------------------------------------------------------------------

fdc_init:
	; Configure
	mov bl, 0x13
	call fdc_data_wr
	xor bl, bl
	call fdc_data_wr
	mov bl, (0 << 6) | (0 << 5) | (1 << 4) | (8 - 1)
	call fdc_data_wr
	xor bl, bl
	call fdc_data_wr

	; Перейти в режим сброса
	mov dx, FDC_DOR
	xor al, al
	out dx, al

	; Задержка
	out 0x80, al

	; Настроить DOR: Select Drive 0, Reset 1 (не в режиме сброса), DMA 1 (DMA вместо PIO), 
	mov dx, FDC_DOR
	mov al, (1 << 3) | (1 << 2) | 0
	out dx, al

	; Подождать IRQ
	call fdc_wait_irq

	; Sense Interrupt
	call fdc_sense

	; Скорость 500 Kbps
	mov dx, FDC_CCR
	xor al, al
	out dx, al
	mov dx, FDC_CCR
	xor al, al
	out dx, al

	; Specify
	mov bl, 0x03
	call fdc_data_wr
	mov bl, 8 << 4 | 15
	call fdc_data_wr
	mov bl, 1 << 1 | 0
	call fdc_data_wr

	; Configure
	mov bl, 0x13
	call fdc_data_wr
	xor bl, bl
	call fdc_data_wr
	mov bl, (0 << 6) | (0 << 5) | (1 << 4) | (8 - 1)
	call fdc_data_wr
	xor bl, bl
	call fdc_data_wr

	; Включить мотор
	call fdd_motor_on

	; Recalibrate
	call fdc_recalibrate
	jc .error

	; Выключить мотор
	call fdd_motor_off

	; Инициализировать DMA
	call fdc_init_dma

	clc
	ret
.error:
	stc
	ret

; ------------------------------------------------------------------

; Прочитать/записать цилиндр диска привода FDD
;
; Номер головки: BL
; Цилиндр: BH
; Направление: CF (0 = Читать, 1 = Писать)
fdd_do_cyl:
	pushad
	push bx
	pushf

	; Переход головки к цилиндру командой Seek
	call fdc_seek

	; 50 мс после Seek
	mov edx, PIT_FREQ/1000*50
	call sleep_ticks
	
	popf
	jc .write
.read:
	; DMA Read режим
	call fdc_dma_rd

	; Команда Read
	mov bl, 0x46
	call fdc_data_wr
	
	jmp .cmd_sent
.write:
	; DMA Write режим
	call fdc_dma_wr

	; Команда Write
	mov bl, 0x45
	call fdc_data_wr
.cmd_sent:

	; (head << 2) | drive
	pop bx
	push bx
	shl bl, 2
	call fdc_data_wr

	; Цилиндр
	pop bx
	push bx
	mov bl, bh
	call fdc_data_wr

	; Головка
	pop bx
	call fdc_data_wr

	; Сектор
	mov bl, 1
	call fdc_data_wr

	; Байтов на сектор
	mov bl, 2
	call fdc_data_wr

	; 18 секторов на дорожку
	mov bl, 18
	call fdc_data_wr

	; GAP1
	mov bl, 0x1B
	call fdc_data_wr

	; Длина (0xFF если не 0 байтов на сектор)
	mov bl, 0xFF
	call fdc_data_wr

	; Подождать IRQ
	call fdc_wait_irq

	; Прочитать то, что вернул вызов
	call fdc_data_rd
	call fdc_data_rd
	call fdc_data_rd
	call fdc_data_rd
	call fdc_data_rd
	call fdc_data_rd
	call fdc_data_rd

	popf
	popad
	clc
	ret

; ------------------------------------------------------------------

; Данные
section .data

fdc_irq_fired db 0