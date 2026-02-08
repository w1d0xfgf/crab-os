	; Стек фрейм
	push ebp
	mov ebp, esp
	sub esp, 4

	cld
	
	; Скрыть курсор
	mov ah, 00010000b
	call set_cursor
	
	; Вывести сообщение
	mov esi, flpcp_msg_disk1
	call .prompt
	jc .exit
	
	; Очистить экран и вывести сообщение
	mov esi, flpcp_msg_prepare
	call .msg

	; Включить мотор флоппи диска
	call fdd_motor_on
	
	; Калибрация флоппи диска
	call fdc_recalibrate
	jnc .rno_error1
.rerror1:
	; Ошибка
	mov esi, flpcp_msg_error
	call .msg
	mov byte [key_queue_top], 0
	call wait_key
	jmp .exit
.rno_error1:
	
	; Выделить память
	mov ecx, (18 * 80 * 2 * 512 + 4095) / 4096
	call mem_alloc
	jc .exit
	mov [ebp-4], ebx
	shl ebx, 12
	push ebx
	
	; Прочитать данные с флоппи диска
	mov esi, flpcp_msg_transfer
	call .msg
	mov edi, ebx
	mov cl, 0
.rloop1:
	mov ch, 0
	.rloop2:
		mov bl, ch
		mov bh, cl
		clc
		call fdd_do_cyl
		
		push cx
		mov cx, 0
		mov esi, 0x1000
		.rcopyloop:
			movsb

			inc cx
			cmp cx, 512 * 18
			jb .rcopyloop
		pop cx
		
		inc ch
		cmp ch, 2
		jb .rloop2
	inc cl
	cmp cl, 80
	jb .rloop1

	; Выключить мотор флоппи диска
	call fdd_motor_off

	; Очистить экран и вывести сообщения
	mov esi, flpcp_msg_disk2
	call .prompt
	jc .exit
	mov esi, flpcp_msg_write
	call .prompt
	jc .exit

	; Включить мотор флоппи диска
	call fdd_motor_on

	; Калибрация флоппи диска
	call fdc_recalibrate
	jnc .rno_error2
.rerror2:
	; Ошибка
	mov esi, flpcp_msg_error
	call .msg
	mov byte [key_queue_top], 0
	call wait_key
	jmp .exit_free
.rno_error2:

	; Записать данные на флоппи диск
	mov esi, flpcp_msg_transfer
	call .msg
	pop ebx
	mov esi, ebx
	mov cl, 0
.wloop1:
	mov ch, 0
	.wloop2:
		push cx
		mov edi, 0x1000
		mov cx, 0
		.wcopyloop:
			movsb
			inc cx
			cmp cx, 512 * 18
			jb .wcopyloop
		pop cx

		mov bl, ch
		mov bh, cl
		stc
		call fdd_do_cyl
		
		inc ch
		cmp ch, 2
		jb .wloop2
	inc cl
	cmp cl, 80
	jb .wloop1

	jmp .exit

.exit_free:
	mov ebx, [ebp-4]
	mov ecx, (18 * 80 * 2 * 512 + 4095) / 4096
	call mem_free
.exit:
	; Выключить мотор флоппи диска
	call fdd_motor_off
	
	; Вернуть курсор
	mov ah, 00000000b
	call set_cursor
	
	; Вернуть GUI
	call init_gui

	mov esp, ebp
	pop ebp	
	ret
	
.prompt:
	; Вывести сообщение
	push esi
	call clear_screen
	mov byte [pos_x], 0
	mov byte [pos_y], 0
	pop esi
	call print_str
	call flush_buffer
	
	; Подождать нажатия клавиши
	mov byte [key_queue_top], 0
	call wait_key
	dec byte [key_queue_top]
	movzx ebx, byte [key_queue_top]
	mov al, [key_queue + ebx]
	
	; Esc
	cmp al, 0x01
	je .prompt_esc

	clc
	ret
.prompt_esc:
	stc
	ret

.msg:
	pushad
	push esi
	call clear_screen
	mov byte [pos_x], 0
	mov byte [pos_y], 0
	mov esi, flpcp_msg_transfer
	pop esi
	call println_str
	call flush_buffer
	popad
	ret