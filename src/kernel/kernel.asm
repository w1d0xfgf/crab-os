; ------------------------------------------------------------------
; Ядро
; ------------------------------------------------------------------

; Компиляция для 32 бит
bits 32

%include "src/const.asm"

extern set_cursor
extern mouse_init
extern disable_blink
extern init_idt_and_pic
extern os_entry

global kernel_entry
global scancode_to_ascii
global scancode_to_ascii_shift
global halt
global total_ram

; Код
section .text

; Стартовая точка ядра
kernel_entry:
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

	; Инициализировать мышку
	call mouse_init

	; Получить total_ram
	mov eax, dword [0x500]
	mov [total_ram], eax
	mov eax, dword [0x504]
	mov [total_ram + 4], eax

	sti
	
	; Отключить VGA мигание
	call disable_blink

	; Установить форму курсора
	mov ah, 00000000b
	call set_cursor

	jmp os_entry
	
halt:
	hlt
	jmp halt

; ------------------------------------------------------------------

; Данные
section .data

%include "src/kernel/data.asm"

total_ram dq 0

; Неинициализированные данные
section .bss

; 4 КиБ стек
stack_bottom:
	resb 4096
stack_top: