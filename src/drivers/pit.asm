; ------------------------------------------------------------------
; Драйвер Programmable Interval Timer
; ------------------------------------------------------------------

PIT_FREQ equ 10000	; Частота PIT

; ------------------------------------------------------------------

; ISR PIT прерывания
pit_stub:
	pushad
	push es
	push ds

	mov ax, DATA_SEL
	mov es, ax
	mov ds, ax

	; Сохранить контекст
	inc dword [pit_ticks]
	
	; PIC EOI
	mov al, PIC_EOI
	out PIC1, al

	pop ds
	pop es
	popad

	iretd
	
pit_ticks dd 0	; Количество тиков PIT

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