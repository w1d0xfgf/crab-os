; Проверить включена ли A20 Line
;
; Статус A20: EDX (1 = включена, 0 = выключена)
; Меняет: EAX, EDX, ESI, EDI
check_A20:
	mov edi, 0x112345  		; Адрес 1 (если A20 Line выключена, будет wrap-around и адрес станет 0x012345)
	mov esi, 0x012345  		; Адрес 2
	mov [edi], byte 4321	; Записать два разных значения
	mov [esi], byte 1234	; 

	mov eax, [edi]			; Если значения не равны A20 Line включена
	cmp [esi], eax			;
	jne .A20_on				;

	xor edx, edx			; Если значения равны A20 Line выключена
	ret						;
.A20_on:
	mov edx, 1

	ret

; Включить A20 Line
;
; Меняет: EAX, EDX, ESI, EDI
enable_A20:
	cli

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

	sti

	; Если A20 Line не включена значит ошибка
	call check_A20
	test edx, edx
	jz .A20_error

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
.A20_error:
	; Скрыть курсор
	mov ah, 0b00010000
	call set_cursor

	; Очистить экран цветом vga_attr
	mov byte [vga_attr], 0x1F
	call clear_screen
	
	; Вывести A20_error_msg на экран
	mov esi, A20_error_msg
	mov byte [pos_x], 0
	mov byte [pos_y], 0
	call println_str

	jmp done
A20_error_msg db 'A20 Line error', 0