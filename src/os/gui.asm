; ------------------------------------------------------------------
; GUI
; ------------------------------------------------------------------

; Инициализирует весь GUI
;
; Меняет: EAX, EBX, ECX, EDX, ESI, EDI
init_gui:
	mov byte [vga_attr], 0x07
	
	call clear_screen
	
	; Инициализация GUI ОС
	mov byte [vga_attr], 0x60
	mov byte [pos_x], 0
	mov byte [pos_y], 0
	mov esi, os_gui_init
	call println_str
	mov byte [vga_attr], 0x07
	
	; Инициализация GUI командной строки
	mov al, '>'
	call print_char
	mov byte [pos_x], 0
	inc byte [pos_y]
	
	; Курсор в начало командной строки
	mov byte [pos_y], 1
	mov byte [pos_x], 2
	call cursor_to_pos
	
	ret
; GUI ОС
os_gui_init:
	db ' CrabOS ', 0xB3, '                                                   ', 0xB3, '                   ', 0

; Обновляет GUI времени и даты
;
; Меняет: EAX, EBX, ECX, EDX, ESI, EDI
update_gui:
	; Позиции GUI времени и даты
	TIME_GUI_POS_X equ 62
	TIME_GUI_POS_Y equ 0
	DATE_GUI_POS_X equ 71
	DATE_GUI_POS_Y equ 0
	
	mov byte [vga_attr], 0x06
	
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
	mov byte [pos_x], 6 + TIME_GUI_POS_X
	mov byte [pos_y], TIME_GUI_POS_Y
	movzx eax, bl
	mov [reg8], al
	call print_reg8_hex
	
	mov byte [pos_x], 3 + TIME_GUI_POS_X
	mov byte [pos_y], TIME_GUI_POS_Y
	pop ebx
	movzx eax, bh
	mov [reg8], al
	call print_reg8_hex
	
	mov byte [pos_x], 0 + TIME_GUI_POS_X
	mov byte [pos_y], TIME_GUI_POS_Y
	pop ecx
	movzx eax, cl
	mov [reg8], al
	call print_reg8_hex
	
	; ":" во времени
	mov byte [pos_x], 2 + TIME_GUI_POS_X
	mov al, ':'
	call print_char
	
	mov byte [pos_x], 5 + TIME_GUI_POS_X
	mov al, ':'
	call print_char
	
	; Дата
	mov byte [pos_x], DATE_GUI_POS_X
	mov byte [pos_y], DATE_GUI_POS_Y
	pop ecx
	movzx eax, ch
	mov [reg8], al
	call print_reg8_hex

	mov byte [pos_x], 3 + DATE_GUI_POS_X
	mov byte [pos_y], DATE_GUI_POS_Y
	pop edx
	movzx eax, dl
	mov [reg8], al
	call print_reg8_hex

	mov byte [pos_x], 6 + DATE_GUI_POS_X
	mov byte [pos_y], DATE_GUI_POS_Y
	pop edx
	movzx eax, dh
	mov [reg8], al
	call print_reg8_hex
	
	; "/" в дате
	mov byte [pos_x], 2 + DATE_GUI_POS_X
	mov byte [pos_y], DATE_GUI_POS_Y
	mov al, '/'
	call print_char
	
	mov byte [pos_x], 5 + DATE_GUI_POS_X
	mov byte [pos_y], DATE_GUI_POS_Y
	mov al, '/'
	call print_char
	
	; Восстановить позицию
	pop eax
	mov [pos_x], al
	mov [pos_y], ah
	
	ret