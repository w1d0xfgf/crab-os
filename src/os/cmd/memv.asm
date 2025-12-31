	; Скрыть курсор
	mov ah, 00010000b
	call set_cursor

	; Изначальная позиция это метка kernel_entry
	mov ebx, kernel_entry
	mov dword [memv_location], ebx
.reload:
	; Очистить экран и сбросить позицию
	mov byte [pos_x], 0
	mov byte [pos_y], 0
	call clear_screen

	; Напечатать memv_help
	mov esi, memv_help
	call println_str

	; Напечатать adress_msg
	mov esi, adress_msg
	call print_str

	; Напечатать адрес
	mov esi, dword [memv_location]
	mov [reg32], esi
	call print_reg32_hex

	; Следующая строка
	inc byte [pos_y]
	mov byte [pos_x], 0

	; Переместить адрес в ESI
	mov esi, dword [memv_location]

	; Количество итераций
	mov ecx, 20
.loop:
	; Сохранить ECX
	push ecx
	
	; Количество итераций
	mov ecx, 0x40
.loop2:
	; Загрузить символ в AL из ESI
	lodsb
	mov [reg8], al

	; Созранить регистры и напечатать символ
	push esi
	push ecx
	call print_char
	pop ecx
	pop esi
	
	; Проверить, конец ли цикла
	dec ecx
	jnz .loop2


	; Восстановить ECX
	pop ecx

	; Следующий ряд
	inc byte [pos_y]
	mov byte [pos_x], 0

	; Проверить, конец ли цикла
	dec ecx
	jnz .loop

	; Отобразить
	call flush_buffer

	; Обработать нажатие клавиши
.check_key:
	call wait_key
	
	; Scancode
	movzx ebx, byte [key_queue_top]
	dec ebx
	mov al, [key_queue + ebx]
	cmp byte [key_queue_top], 0
	je .check_key
	dec byte [key_queue_top]

	; W/U
	cmp al, 0x11
	je .forward
	cmp al, 0x16
	je .fast_forward

	; S/D
	cmp al, 0x1F
	je .backward
	cmp al, 0x20
	je .fast_backward

	; Escape
	cmp al, 0x01
	je .exit

	; Заного
	jmp .check_key

.forward:
	add dword [memv_location], 0x040
	jmp .reload
.fast_forward:
	add dword [memv_location], 0x400
	jmp .reload
.backward:
	sub dword [memv_location], 0x040
	jmp .reload
.fast_backward:
	sub dword [memv_location], 0x400
	jmp .reload
.exit:
	; Вернуть курсор
	mov ah, 00000000b
	call set_cursor

	; Вернуть GUI
	call init_gui

	ret