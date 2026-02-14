bits 32

global _start
extern kmain

; GDT селекторы
CODE_SEL equ 0x08 ; Код Ring 0
DATA_SEL equ 0x10 ; Данные Ring 0

section .text

jmp _start

dw memory_map

_start:
	; Отключить прерывания
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
	mov ebp, esp

	; Вызов kmain
	mov eax, memory_map
	push eax
	call kmain

	cli
	hlt
	
section .data

align 8
memory_map times 24*128 db 0

section .bss

stack_bottom:
	resb 4096
stack_top: