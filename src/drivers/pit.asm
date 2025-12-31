; ------------------------------------------------------------------
; Драйвер Programmable Interval Timer
; ------------------------------------------------------------------

bits 32

%include "src/const.asm"

global pit_stub
global sleep_ticks

global pit_ticks

; ------------------------------------------------------------------

; Код
section .text

; ISR PIT прерывания
pit_stub:
	; Сохранить контекст
	pushad
	push ds

	; Установить сегменты
	mov ax, DATA_SEL
	mov ds, ax

	; Увеличить счётчик
	inc dword [pit_ticks]
	
	; PIC EOI
	mov al, PIC_EOI
	out PIC1, al
	
	; Восстановить контекст
	pop ds
	popad

	iretd

; ------------------------------------------------------------------

; Подождать определённое количество тиков PIT
;
; Тики: EDX
sleep_ticks:
	; EAX = Тики + Мс
	cli
	mov eax, [pit_ticks]
	sti
	add eax, edx
.wait:
	; Подождать прерывание PIT для того что бы не тратить ресурсы
	hlt

	; Если тики PIT меньше EAX, повторить
	cli
	cmp [pit_ticks], eax
	sti
	jb .wait
	
	ret

; ------------------------------------------------------------------

section .data

pit_ticks dd 0	; Количество тиков PIT