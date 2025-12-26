; ------------------------------------------------------------------
; Драйвер мышки (работает только на эмуляторах)
; ------------------------------------------------------------------

; ISR мыши
mouse_stub:
	; Сохранить состояние
	pushad
	push ds
	push es

	; Установить сегменты
	mov ax, DATA_SEL
	mov ds, ax
	mov es, ax

	; Вызвать хендлер
	call mousehandle

	mov al, PIC_EOI
	out 0xA0, al	; EOI для Slave PIC
	out 0x20, al	; EOI для Master PIC

	; Восстановить состояние
	pop es
	pop ds
	popad

	iretd

; ------------------------------------------------------------------

; Комментарии пока что на англ и два таба вместо одного, код сворованный с форумов OSDev, потом изменю

;variables
packetsize: db 0
resolution: db 3
samplerate: db 200

mouseinit:
		;initialize legacy ps2 user input
		xor			eax, eax
		mov			dl, 2
		call			ps2wait
		mov			al, 0A8h
		out			64h, al
		;get ack
		call			ps2rd
		;some compaq voodoo magic to enable irq12
		mov			dl, 2
		call			ps2wait
		mov			al, 020h
		out			64h, al
		mov			dl, 1
		call			ps2wait
		in			al, 60h
		bts			ax, 1
		btr			ax, 5
		mov			bl, al
		mov			dl, 2
		call			ps2wait
		mov			al, 060h
		out			64h, al
		call			ps2wait
		mov			al, bl
		out			60h, al
		;get optional ack
		mov			dl, 1
		call			ps2wait

		;restore to defaults
		mov			al, 0F6h
		call			ps2wr
		;enable Z axis
		mov			al, 0F3h
		call			ps2wr
		mov			al, 200
		call			ps2wr
		mov			al, 0F3h
		call			ps2wr
		mov			al, 100
		call			ps2wr
		mov			al, 0F3h
		call			ps2wr
		mov			al, 80
		call			ps2wr
		mov			al, 0F2h
		call			ps2wr
		call			ps2rd
		mov			byte [packetsize], 3
		or			al, al
		jz			.noZaxis
		mov			byte [packetsize], 4
.noZaxis:	;enable 4th and 5th buttons
		mov			al, 0F3h
		call			ps2wr
		mov			al, 200
		call			ps2wr
		mov			al, 0F3h
		call			ps2wr
		mov			al, 200
		call			ps2wr
		mov			al, 0F3h
		call			ps2wr
		mov			al, 80
		call			ps2wr
		mov			al, 0F2h
		call			ps2wr
		call			ps2rd

		;set sample rate
		mov			al, 0F3h
		call			ps2wr
		mov			al, byte[samplerate] ;200
		call			ps2wr
		;set resolution
		mov			al, 0E8h
		call			ps2wr
		mov			al, byte [resolution] ;3
		call			ps2wr
		;set scaling 1:1
		mov			al, 0E6h
		call			ps2wr
		;enable
		mov			al, 0F4h
		call			ps2wr

		;reset variables
		xor			eax, eax
		mov			dword [cnt], eax
		mov			dword [y], eax

;dl=1 read, dl=2 write
ps2wait:	mov			ecx, 1000
.b:		in			al, 64h
		and			al, dl
		jnz			.f
		dec			ecx
		jnz			.b
.f:		ret
ps2wr:	mov			dh, al
		mov			dl, 2
		call			ps2wait
		mov			al, 0D4h
		out			64h, al
		call			ps2wait
		mov			al, dh
		out			60h, al
		;no ret, fall into read code to read ack
ps2rd:	mov			dl, 1
		call			ps2wait
		in			al, 60h
		ret

	


		;variables
packet: dd 0	;raw packet
;keep them together
cnt: db 0		;byte counter
buttons: db 0	;buttons, each bit represents one button from bits 1-5, 0-released, 1-pressed
x: dw 0		;position on x,y,z axis
y: dw 0
z: dw 0

mousehandle:
		xor			ecx, ecx
		mov			cx, 1000
		xor			eax, eax
.waitkey:	in			al, 64h
		dec			cl
		jnz			.f
		ret
.f:		and			al, 20h
		jz			.waitkey
		in			al, 60h
		mov			cl, al
		in			al, 61h
		out			61h, al
		xor			ebx, ebx
		mov			bl, byte [cnt]
		add			ebx, packet
		mov			byte [ebx], cl
		inc			byte [cnt]
		mov			bl, byte [cnt]
		cmp			bl, byte [packetsize]
		jb			.end
		mov			byte [cnt], 0

		;get buttons state
 		mov			al, byte [packet]
		and			al, 7
		mov			cl, byte [packet+3]
		and			cl, 0F0h
		cmp			cl, 0F0h
		je			.no45btn
		shr			cl, 1
		or			al, cl
.no45btn:	mov			byte [buttons], al
		;get delta X
		movsx		eax, byte [packet+1]
		add			word [x], ax
		;get delta Y
		movsx		eax, byte [packet+2]
		sub			word [y], ax
		;get delta Z
		mov			cl, byte [packet+3]
		and			cl, 0Fh
		cmp			cl, 8
		jb			.f2
		or			cl, 0F0h
.f2:	movsx		eax, cl
		add			word [z], ax

;buttons,x,y,z variables contains valid values now.
;here you possibly want to send a mouse event message to your gui process.
.end:		ret