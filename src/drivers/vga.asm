; ------------------------------------------------------------------
; Драйвер VGA
; ------------------------------------------------------------------

VIDEO_MEM equ 0xB8000 ; Адрес VGA текстового буфера

; Получить смещение в символах которое соответствует текущей позиции
;
; Меняет: EAX, EBX, ECX
get_pos_offset:
	; Смещение = x + y * 80
	
	xor ecx, ecx			; ECX = 0
	movzx eax, byte [pos_y]	; EAX = Текущий Y
	mov ebx, 80				; Вычислить смещение: Y * 80
	mul ebx 				; EAX *= EBX
	add ecx, eax			; Добавить смещение по Y
	
	movzx eax, byte [pos_x] ; EAX = pos_x
    add ecx, eax			; Добавить смещение по X
	
	ret
	
; ------------------------------------------------------------------
	
; Получить адрес который соответствует текущей позиции
;
; Адрес: EDI
; Меняет: EAX, EBX, EDI
get_pos_addr:
	; Смещение = 2 * (x + y * 80)
	; Адрес = VGA буфер + смещение
	
	xor edi, edi			; EDI = 0
	movzx eax, byte [pos_y]	; EAX = Текущий Y
	mov ebx, 80				; Вычислить смещение: Y * 80
	mul ebx 				; EAX *= EBX
	add edi, eax			; Добавить смещение по Y
	
	movzx eax, byte [pos_x]	; EAX = Текущий X
	add edi, eax			; Добавить смещение по X
	
	shl edi, 1 				; EDI *= 2
	
	add edi, VIDEO_MEM  	; EDI += Адрес VGA текстового буфера
	
	ret
	
; ------------------------------------------------------------------

; Напечатать символ на экран
; 
; Символ: AL
; Меняет: BL, EDI
print_char:
	push ax ; Сохранить символ

	call get_pos_addr			; Адрес записи -> EDI
	
	pop ax ; Вернуть символ

	; Запись в VGA текстовый буфер
    mov [edi], al 			; Записать символ
    mov bl, [vga_attr]      ; Загрузить атрибут
    mov [edi + 1], bl       ; Записать его
	inc byte [pos_x]		; Следующая позиция на экране
	
	ret
	
; ------------------------------------------------------------------

; Напечатать строку на экран
;
; Адрес строки: ESI
; Меняет: AL, BL, ESI, EDI
print_str:
	call get_pos_addr			; Адрес записи -> EDI
	
	mov al, [esi] 				; Загрузка символа
	
    cmp al, 0 					; Код 0 - NULL terminator
    je .done  					; Завершить
	cmp al, 13					; Код 13 - \r
    je .carriage				; Возвращение каретки
    cmp al, 10					; Код 10 - \n
    je .newline					; Новая линия
	
	; Запись в VGA тектовый буфер
    mov [edi], al 				; Записать символ
    mov bl, [vga_attr]          ; Загрузить атрибут
    mov [edi + 1], bl           ; Записать его

	; Следующая итерация
	inc byte [pos_x]
.next_iter:
    inc esi
    jmp print_str 
.done:
	ret
	
.newline:
	inc byte [pos_y] 		; Новая линия	
    jmp .next_iter
.carriage:
	mov byte [pos_x], 0 	; Возврат каретки
	jmp .next_iter
	
; ------------------------------------------------------------------

; Очистить экран
;
; Меняет: AX, ECX, EDI
clear_screen:
	mov ecx, 2000			; Счётчик = 2000 (размер экрана 80x25 символов)
	mov edi, VIDEO_MEM		; Адрес VGA текстового буфера
	
	mov al, ' '				; Символ
	mov ah, [vga_attr]		; Атрибут
	
	; AX -> EDI, EDI += 2, ECX-- до того как ECX = 0
	rep stosw

	ret

; ------------------------------------------------------------------

; Очистить одну линию
;
; Линия: EAX
; Меняет: AX, ECX, EDI
clear_line:
	mov ecx, 80			; Счётчик = 80 (размер линии 80 символов)

	mov edi, VIDEO_MEM	; Адрес VGA текстового буфера
	mov ebx, 80			; Вычислить смещение
	mul ebx 			; 
	add edi, eax		; Перейти к линии
	
	mov al, ' '			; Символ
	mov ah, [vga_attr]	; Атрибут
	
	; AX -> EDI, EDI += 2, ECX-- до того как ECX = 0
	rep stosw

	ret
	
; ------------------------------------------------------------------

; Переместить курсор в текущую позицию
;
; Меняет: AL, DX, ECX
cursor_to_pos:
	; Получить смещение в символах
    call get_pos_offset
	
    ; Записать low byte
    mov dx, 0x03D4
    mov al, 0x0F
    out dx, al
    mov dx, 0x03D5
    mov al, cl
    out dx, al

    ; Записать high byte
    mov dx, 0x03D4
    mov al, 0x0E
    out dx, al
    mov dx, 0x03D5
    mov al, ch
    out dx, al

    ret
	
; ------------------------------------------------------------------
	
; Установить форму и видимость курсора
;
; Значение: AH
; Меняет: AL, DX, ECX
set_cursor:
	mov dx, 0x3D4
	mov al, 0xA
	out dx, al

	inc dx
	mov al, ah
	out dx, al

	ret

; ------------------------------------------------------------------

; VGA атрибут (цвет) печати на экран
vga_attr db 0x07

; Координаты в символах печати на экран
pos_x db 0
pos_y db 0