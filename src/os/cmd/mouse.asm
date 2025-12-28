MOUSE_X_LIMIT equ 79*4
MOUSE_Y_LIMIT equ 24*8

	; Цвет 0x07 и скрытый курсор
	mov byte [vga_attr], 0x07
	mov ah, 00010000b
	call set_cursor
.loop:
	; Получить Scancode клавиши
	movzx ebx, byte [key_queue_top]
	dec ebx
	mov al, [key_queue + ebx]
	cmp byte [key_queue_top], 0
	je .skip_key
	dec byte [key_queue_top]

	; Выйти если Scancode клавиши Escape
	cmp al, 0x01
	je .exit
.skip_key:

	; Очистить экран
	call clear_screen

	; Текст
	mov byte [pos_x], 0
	mov byte [pos_y], 0
	mov esi, .msg
	call print_str

	; Курсор

	; Позиция X
	movsx eax, word [mouse_x]
	cmp eax, 0
	jl .x_too_low
	cmp eax, MOUSE_X_LIMIT
	jg .x_too_high
.pos_x_done:
	shr eax, 2
	mov [pos_x], al

	; Позиция Y
	movsx eax, word [mouse_y]
	cmp eax, 0
	jl .y_too_low
	cmp eax, MOUSE_Y_LIMIT
	jg .y_too_high
.pos_y_done:
	shr eax, 3
	mov [pos_y], al

	; Цвет
	test byte [mouse_state], 00000001b
	jnz .green
	jmp .col_endif
.green:
	mov byte [vga_attr], 0x02
.col_endif:

	; Отрисовать
	mov al, 0xDB
	call print_char

	; Вернуть цвет
	mov byte [vga_attr], 0x07

	; Подождать прерывание
	hlt

	; Повторить цикл
	jmp .loop

.x_too_low:
	mov eax, 0
	jmp .pos_x_done
.x_too_high:
	mov eax, MOUSE_X_LIMIT
	jmp .pos_x_done
.y_too_low:
	mov eax, 0
	jmp .pos_y_done
.y_too_high:
	mov eax, MOUSE_Y_LIMIT
	jmp .pos_y_done
.exit:
	; Вернуть курсор
	mov ah, 00000000b
	call set_cursor

	; Вернуть GUI
	call init_gui

	ret
.msg db 'Press <Escape> to exit', 0