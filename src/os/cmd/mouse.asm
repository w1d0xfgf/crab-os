	; Цвет 0x07 и скрытый курсор
	mov byte [vga_attr], 0x07
	mov ah, 00010000b
	call set_cursor
.rep:
	; Подождать прерывания
	hlt

	mov al, ' '
	call print_char
	mov eax, 0
	call clear_line 

	; Scancode
	movzx ebx, byte [key_queue_top]
	dec ebx
	mov al, [key_queue + ebx]
	cmp byte [key_queue_top], 0
	je .skip_key
	dec byte [key_queue_top]

	; Escape
	cmp al, 0x01
	je .exit
.skip_key:

	; Очистить экран и отрисовать (кастомный) курсор
	call clear_screen

	mov byte [pos_x], 0
	mov byte [pos_y], 0
	mov esi, .msg
	call print_str

	movsx eax, word [x]
	cmp eax, 0
	jl .x_below_0
	cmp eax, 79
	jg .x_above_79
.pos_x_done:
	mov [pos_x], al

	movsx eax, word [y]
	cmp eax, 0
	jl .y_below_0
	cmp eax, 24
	jg .y_above_24
.pos_y_done:
	mov [pos_y], al

	mov al, 0xDB
	call print_char

	jmp .rep
.x_below_0:
	mov eax, 0
	jmp .pos_x_done
.x_above_79:
	mov eax, 79
	jmp .pos_x_done
.y_below_0:
	mov eax, 0
	jmp .pos_y_done
.y_above_24:
	mov eax, 24
	jmp .pos_y_done
.exit:
	; Вернуть курсор
	mov ah, 00000000b
	call set_cursor

	; Вернуть GUI
	call init_gui

	ret
.msg db 'Press <Escape> to exit', 0