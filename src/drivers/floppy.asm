; ------------------------------------------------------------------
; Драйвер Floppy Disk Controller
; ------------------------------------------------------------------

bits 32

extern sleep_ticks

global fdc_irq_handler
global fdc_init
global fdc_read

%include "src/const.asm"

FDC_DOR equ 0x3F2
FDC_MSR equ 0x3F4
FDC_DATA equ 0x3F5
FDC_CTRL equ 0x3F7

%macro outb 2
	mov al, %1
	out %2, al
%endmacro

; ------------------------------------------------------------------

section .text

fdc_irq_handler:
	; Сохранить состояние
	pushad
	push ds
	push es

	; Установить сегменты
	mov ax, DATA_SEL
	mov es, ax
	mov ds, ax

	; Вызвать хендлер
	call fdc_handler
	
	; Отправить EOI Master PIC
	mov al, PIC_EOI
	out PIC1, al

	; Восстановить состояние
	pop es
	pop ds
	popad

	iretd

; ------------------------------------------------------------------

fdc_handler:
	mov byte [fdc_irq_fired], 1
	ret

; ------------------------------------------------------------------

fdc_wait_int:
	mov ecx, 0xFFFFFF
.loop:
	cmp byte [fdc_irq_fired], 1
	je .done
	dec ecx
	jz .error
	jmp .loop
.done:
	mov byte [fdc_irq_fired], 0
	clc
	ret
.error:
	stc
	ret

; ------------------------------------------------------------------

fdc_init_dma:
	outb 0x06, 0x0A
	outb 0xFF, 0x0C
	outb 0x00, 0x04
	outb 0x10, 0x04
	outb 0x00, 0x81
	outb 0xFF, 0x0C
	outb 0xFF, 0x05
	outb 0x23, 0x05
	outb 0x4A, 0x0B
	outb 0x02, 0x0A

	ret

; ------------------------------------------------------------------

fdc_dma_wr:
	outb 0x06, 0x0A
	outb 0x5A, 0x0B
	outb 0x02, 0x0A

	ret

; ------------------------------------------------------------------

fdc_dma_rd:
	outb 0x06, 0x0A
	outb 0x56, 0x0B
	outb 0x02, 0x0A

	ret

; ------------------------------------------------------------------

fdc_data_wr:
	mov ecx, 0xFFFF
	mov dx, FDC_MSR
.loop:
	in al, dx
	and al, 0xC0
	cmp al, 0x80
	je .done
	dec ecx
	jz .error
	jmp .loop
.done:
	mov dx, FDC_DATA
	mov al, bl
	out dx, al
	clc
	ret
.error:
	stc
	ret

; ------------------------------------------------------------------

fdc_data_rd:
	mov ecx, 0xFFFF
	mov dx, FDC_MSR
.loop:
	in al, dx
	and al, 0xC0
	cmp al, 0xC0
	je .done
	dec ecx
	jz .error
	jmp .loop
.done:
	mov dx, FDC_DATA
	in al, dx
	clc
	ret
.error:
	stc
	ret

; ------------------------------------------------------------------

fdc_sense:
	mov bl, 0x08
	call fdc_data_wr
	call fdc_data_rd
	mov bl, al
	call fdc_data_rd
	ret

; ------------------------------------------------------------------

fdc_calibrate:
	push ax
	mov bl, 0x07
	call fdc_data_wr
	pop bx
	call fdc_data_wr
	call fdc_wait_int

	call fdc_sense
	test bl, 0xC0
	jnz .error
	test al, al
	jnz .error

	clc
	ret
.error:
	stc
	ret

; ------------------------------------------------------------------

fdc_seek:
	push ax
	push bx
	mov bl, 0x0F
	call fdc_data_wr
	pop bx
	shl bl, 0x02
	call fdc_data_wr
	pop bx
	call fdc_data_wr

	call fdc_wait_int

	call fdc_sense
	cmp bl, 0xC0
	jne .error

	clc
	ret
.error:
	stc
	ret

; ------------------------------------------------------------------

fdc_init:
	; Motor 0 disable, DMA enable, Reset enable, Select drive 0
	mov al, (0 << 4) | (1 << 3) | (0 << 2) | (00b)
	mov dx, FDC_DOR
	out dx, al

	; 10 мс
	mov edx, PIT_FREQ/1000*10
	call sleep_ticks

	; Motor 0 enable, DMA enable, Reset disable, Select drive 0
	mov al, (1 << 4) | (1 << 3) | (1 << 2) | (00b)
	mov dx, FDC_DOR
	out dx, al

	; Подождать прерывание
	call fdc_wait_int

	; 500 мс для раскрутки мотора (3.5")
	mov edx, PIT_FREQ/1000*500
	call sleep_ticks
	
	; 500 Kbps
	mov dx, FDC_CTRL
	xor al, al
	out dx, al

	; Specify
	mov bl, 0x03
	call fdc_data_wr

	; SRT: 0x08, HLT: 0x05, HUT: 0x0F, NDMA: 0
	mov bl, (0x08 << 4) | 0x0F
	call fdc_data_wr

	mov bl, (0x05 << 1) | 0
	call fdc_data_wr

	; Recalibrate
	mov al, 00b
	call fdc_calibrate
	jc .error

	call fdc_init_dma

	clc
	ret
.error:
	stc
	ret

; ------------------------------------------------------------------

fdc_read:
	call fdc_dma_rd

	mov ecx, 20
.seek1:
	dec ecx
	jz .seek1_done
	xor ax, ax
	xor bx, bx
	push ecx
	call fdc_seek
	pop ecx
	jc .seek1
.seek1_done:
	
	mov ecx, 20
.seek2:
	dec ecx
	jz .seek2_done
	mov ax, 1 << 2
	xor bx, bx
	push ecx
	call fdc_seek
	pop ecx
	jc .seek2
.seek2_done:
	
	; 300 мс
	mov edx, PIT_FREQ/1000*300
	call sleep_ticks

	mov bl, 0x06 | 0xC0
	call fdc_data_wr
	xor bl, bl
	call fdc_data_wr
	xor bl, bl
	call fdc_data_wr
	xor bl, bl
	call fdc_data_wr
	mov bl, 1
	call fdc_data_wr
	mov bl, 2
	call fdc_data_wr
	mov bl, 18
	call fdc_data_wr
	mov bl, 0x1B
	call fdc_data_wr
	mov bl, 0xFF
	call fdc_data_wr
	
	call fdc_wait_int
	
	call fdc_data_rd
	test al, 0xC0
	jnz .error
	test al, 0x08
	jnz .error
	call fdc_data_rd
	test al, 0x80
	jnz .error
	test al, 0x20
	jnz .error
	test al, 0x10
	jnz .error
	test al, 0x80
	jnz .error
	test al, 0x04
	jnz .error
	call fdc_data_rd
	call fdc_data_rd
	call fdc_data_rd
	call fdc_data_rd
	call fdc_data_rd
	
	clc
	ret
.error:
	stc
	ret

; ------------------------------------------------------------------

; Данные
section .data

fdc_irq_fired db 0