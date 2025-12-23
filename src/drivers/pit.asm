; ISR PIT прерывания
system_timer:
	push eax
	
    inc dword [system_timer_ticks]
    mov al, PIC_EOI
    out PIC1, al
	
    pop eax
	
    iret
	
system_timer_ticks dd 0	; Количество тиков PIT

; Подождать определённое количество тиков PIT
;
; Тики: EDX
sleep_ticks:
	; EAX = Тики + Мс
	cli
	mov eax, [system_timer_ticks]
	sti
	add eax, edx
.wait:
	; Подождать прерывание PIT для того что бы не тратить ресурсы
	sti
	hlt
	cli

	; Если тики PIT меньше EAX, повторить
	cli
	cmp [system_timer_ticks], eax
	sti
	jb .wait

	ret