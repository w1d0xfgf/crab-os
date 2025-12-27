; ------------------------------------------------------------------
; A20 Line
; ------------------------------------------------------------------

; Включить A20 Line
;
; Меняет: EAX, EDX, ESI, EDI
enable_A20:
	call .A20_wait
	mov al, 0xAD
	out 0x64, al

	call .A20_wait
	mov al, 0xD0
	out 0x64, al

	call .A20_wait2
	in al, 0x60
	push eax

	call .A20_wait
	mov al, 0xD1
	out 0x64, al

	call .A20_wait
	pop eax
	or al, 2
	out 0x60, al

	call .A20_wait
	mov al, 0xAE
	out 0x64, al

	ret
.A20_wait:
	in al,0x64
	test al,2
	jnz .A20_wait
	ret
.A20_wait2:
	in al, 0x64
	test al, 1
	jz .A20_wait2

	ret