; ------------------------------------------------------------------
; Ядро
; ------------------------------------------------------------------

org 0x8000

; Загрузчик ядра
%include "src/boot/stage2.asm"

bits 32

; Interrupt Descriptor Table
%include "src/kernel/idt.asm" 

; Стартовая точка ядра
protected_start:
	cli

	; Сегменты
	mov ax, DATA_SEL
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	
	; Стек
	mov ss, ax
	mov esp, stack_top
	
	; IDT
	call init_idt_and_pic

	sti

	; Инициализировать мышку
	call mouse_init
	
	; Отключить VGA мигание
	call disable_blink
	
	; Установить форму курсора
	mov ah, 00000000b
	call set_cursor

; Сама ОС (GUI, ввод, и т. д.)
%include "src/os/os.asm"

done:
	hlt
	jmp done

; ------------------------------------------------------------------

; Драйвер VGA
%include "src/drivers/vga.asm"

; Драйвер Real Time Clock
%include "src/drivers/rtc.asm"

; Драйвер PC Speaker
%include "src/drivers/speaker.asm"

; ------------------------------------------------------------------

; Функции для печати на экран
%include "src/functions/print.asm"

; Функции для работы со строками
%include "src/functions/str.asm"
	
; ------------------------------------------------------------------

bits 32

; Данные
%include "src/kernel/data.asm"

; 4 КиБ стек
stack_bottom:
	times 4096 db 0
stack_top: