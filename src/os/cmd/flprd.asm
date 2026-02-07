	; Скрыть курсор
	mov ah, 00010000b
	call set_cursor
	
	; Вывести сообщение
	mov esi, flprd_msg_disk
	call print_str
	call flush_buffer
	
	; Подождать нажатия клавиши
	mov byte [key_queue_top], 0
	call wait_key

	; Очистить экран и вывести сообщение
	call clear_screen
	mov esi, flprd_msg_prepare
	mov byte [pos_x], 0
	mov byte [pos_y], 0
	call print_str
	call flush_buffer

	; Включить мотор флоппи диска
	call fdd_motor_on
	
	; Калибрация флоппи диска
	call fdc_recalibrate
	jnc .no_error
.error:
	; Ошибка
	call clear_screen
	mov esi, flprd_msg_error
	mov byte [pos_x], 0
	mov byte [pos_y], 0
	call print_str
	call flush_buffer
	mov byte [key_queue_top], 0
	call wait_key
.no_error:

	; Сбросить location
	mov word [flprd_location], 0
.reload:
	; Очистить экран и сбросить позицию
	mov byte [pos_x], 0
	mov byte [pos_y], 0
	call clear_screen

	; Вывести сообщение и location
	mov esi, flprd_msg_help
	call print_str
	movzx eax, word [flprd_location]
	mov [reg32], eax
	call println_reg32_hex
	call flush_buffer

	; Посчитать head и cylinder из LBA секторов
	mov ax, [flprd_location]

	; Формула для LBA -> CH для 3.5" флоппи диска:
	; Hn (головок) = 2
	; Sn (секторов на дорожку) = 18
	;
	; H = LBA / (Hn * Sn) = LBA / Hn / Sn
	; C = LBA / Sn mod Hn
	;
	; a = LBA / Sn
	; H = a / Hn
	; C = a mod Hn

	; AX = LBA / Sn
	mov bx, ax
	mov cx, 18
	xor dx, dx
	div cx

	; Цилиндры = LBA / Hn, Головки = LBA mod Hn
	xor dx, dx
	mov cx, 2
	div cx

	; Прочитать цилиндр
	mov bl, dl
	mov bh, al
	clc
	call fdd_do_cyl
 
	; Адрес буфера где находятся данные
	mov esi, 0x1000
	xor edx, edx

	; Вычислить смещение:
	; Сектор, начиная с 0 = LBA % SPT, для 3.5" флоппи SPT = 18
	; Размер сектора в памяти = 512
	; Смещение = Сектор * Размер сектора
	movzx eax, word [flprd_location]
	mov ebx, 18
	div ebx
	shl edx, 9
	add esi, edx
	shr edx, 9

	; Вывести сектор
	mov cl, 0
.loop:
	mov ch, 0
.loop2:
	mov al, [esi]
	mov [reg8], al
	push cx
	push esi
	call print_reg8_hex
	pop esi
	pop cx

	inc esi
	inc ch
	cmp ch, 32
	jb .loop2

	inc byte [pos_y]
	mov byte [pos_x], 0
	inc cl
	cmp cl, 16
	jb .loop

	; Отобразить
	call flush_buffer
.check_key:
	call wait_key

	movzx ebx, byte [key_queue_top]
	dec ebx
	mov al, [key_queue + ebx]
	cmp byte [key_queue_top], 0
	je .check_key
	dec byte [key_queue_top]

	; Q / E
	cmp al, 0x10
	je .backward
	cmp al, 0x12
	je .forward

	; Escape
	cmp al, 0x01
	je .exit

	jmp .check_key
.forward:
	inc word [flprd_location]
	jmp .reload
.backward:
	dec word [flprd_location]
	jmp .reload
.exit:
	; Выключить мотор флоппи диска
	call fdd_motor_off
	
	; Вернуть курсор
	mov ah, 00000000b
	call set_cursor
	
	; Вернуть GUI
	call init_gui
	
	ret