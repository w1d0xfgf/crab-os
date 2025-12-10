; ------------------------------------------------------------------
; Функции для GUI
; ------------------------------------------------------------------

; Инициализирует весь GUI
;
; Меняет: EAX, EBX, ECX, EDX, ESI, EDI
init_gui:
	mov byte [attr], 0x07
	
	call clear_screen

	; Инициализация GUI времени и даты
	mov byte [pos_x], 0
	mov byte [pos_y], 0
	mov esi, time_gui_init
	call println_str
	
	; Инициализация GUI командной строки
	mov al, '>'
	call print_char
	mov byte [pos_x], 0
	inc byte [pos_y]
	
	; Инициализация GUI PIT
	mov esi, pit_gui_init
	call print_str
	
	; Курсор в начало командной строки
	mov byte [pos_y], 4
	mov byte [pos_x], 2
	call cursor_to_pos
	
	ret

; Обновляет GUI времени и даты
;
; Меняет: EAX, EBX, ECX, EDX, ESI, EDI
update_gui:
	cli
	
	; Получить время
	call get_rtc_time
	
	; Сохранить позицию
	xor eax, eax
	mov al, [pos_x]
	mov ah, [pos_y]
	push eax
	
	; !!! Поскольку вывод в шестнадцатеричном формате, не нужно конвертировать из BCD
	; !!! Время будет видно в десятичном формате
	
	; Сохранить время
	push edx
	push edx
	push ecx
	push ecx
	push ebx
	
	; Время
	mov byte [pos_x], 6 + 7
	mov byte [pos_y], 0
	movzx eax, bl
	mov [reg8], al
	call print_reg8
	
	mov byte [pos_x], 3 + 7
	mov byte [pos_y], 0
	pop ebx
	movzx eax, bh
	mov [reg8], al
	call print_reg8
	
	mov byte [pos_x], 0 + 7
	mov byte [pos_y], 0
	pop ecx
	movzx eax, cl
	mov [reg8], al
	call print_reg8
	
	; Двоиточия во времени
	mov byte [pos_x], 2 + 7
	mov al, ':'
	call print_char
	
	mov byte [pos_x], 5 + 7
	mov al, ':'
	call print_char
	
	; Дата
	mov byte [pos_x], 0 + 7
	mov byte [pos_y], 2
	pop ecx
	movzx eax, ch
	mov [reg8], al
	call print_reg8

	mov byte [pos_x], 3 + 7
	mov byte [pos_y], 2
	pop edx
	movzx eax, dl
	mov [reg8], al
	call print_reg8

	mov byte [pos_x], 6 + 7
	mov byte [pos_y], 2
	pop edx
	movzx eax, dh
	mov [reg8], al
	call print_reg8
	
	; Точки в дате
	mov byte [pos_x], 2 + 7
	mov byte [pos_y], 2
	mov al, '.'
	call print_char
	
	mov byte [pos_x], 5 + 7
	mov byte [pos_y], 2
	mov al, '.'
	call print_char
	
	; Восстановить позицию
	pop eax
	mov [pos_x], al
	mov [pos_y], ah
	
	sti ; Включить прерывания
	
	ret