; ------------------------------------------------------------------
; Драйвер VGA
; ------------------------------------------------------------------

bits 32

global print_char
global print_str
global clear_screen
global clear_line
global flush_buffer
global set_cursor
global disable_blink
global cursor_to_pos

global vga_attr
global pos_x
global pos_y

VIDEO_MEMORY equ 0xB8000 ; Адрес VGA памяти

; ------------------------------------------------------------------

; Код
section .text

; Получить смещение в символах которое соответствует текущей позиции
;
; Смещение: EAX
; Меняет: EAX, EDX
get_pos_offset:
	; Смещение = x + y * 80
	
	movzx eax, byte [pos_y]
	lea eax, [eax + eax*4]
	shl eax, 4
	movzx edx, byte [pos_x]
	add eax, edx
	
	ret
	
; ------------------------------------------------------------------

; Получить адрес в VGA буфере который соответствует текущей позиции
;
; Адрес: EDI
; Меняет: EAX, EDX, EDI
get_pos_addr:
	; Адрес = Адрес VGA буфера + 2 * (x + y * 80)
	
	call get_pos_offset
	mov edi, eax
	shl edi, 1
	add edi, vga_buffer

	ret
	
; ------------------------------------------------------------------

; Напечатать символ на экран
; 
; Символ: AL
; Меняет: EBX, EDX, EDI
print_char:
	push eax
	call get_pos_addr	; Адрес
	pop eax

	; Запись в VGA текстовый буфер
	mov [edi], al 		; Записать символ
	mov bl, [vga_attr]	; Загрузить атрибут
	mov [edi + 1], bl	; Записать его
	inc byte [pos_x]	; Следующая позиция на экране
	
	ret
	
; ------------------------------------------------------------------

; Напечатать строку на экран
;
; Адрес строки: ESI
; Меняет: EAX, EDX, ESI, EDI
print_str:
	call get_pos_addr	; Адрес
	
	mov al, [esi] 		; Загрузка символа
	
	cmp al, 0			; Код 0 - NULL terminator
	je .done			; Завершить
	cmp al, 13			; Код 13 - \r
	je .carriage		; Возвращение каретки
	cmp al, 10			; Код 10 - \n
	je .newline			; Новая линия
	
	; Запись в VGA тектовый буфер
	mov [edi], al		; Записать символ
	mov al, [vga_attr]	; Загрузить атрибут
	mov [edi + 1], al	; Записать его

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
; Меняет: EAX, ECX, EDI
clear_screen:
	mov ecx, 1000			; Счётчик = 1000 (размер экрана 80x25 символов, запись dword за раз)
	mov edi, vga_buffer		; Адрес VGA текстового буфера
	
	mov al, ' '				; Символ
	mov ah, [vga_attr]		; Атрибут
	shl eax, 16				; Сдвинуть
	mov al, ' '				; Символ
	mov ah, [vga_attr]		; Атрибут
	
	; EAX -> EDI, EDI += 4, ECX-- до того как ECX = 0
	rep stosd

	ret

; ------------------------------------------------------------------

; Очистить одну линию
;
; Линия: EAX
; Меняет: EAX, ECX, EDI
clear_line:
	; Количество символов в линии
	mov ecx, 80

	; Перейти к линии
	; EDI = EAX * 80
	lea edi, [eax + eax*4]
	shl edi, 5
	add edi, eax
	
	; Символ с атрибутом
	mov al, ' '
	mov ah, [vga_attr]
	
	; AX -> EDI, EDI += 2, ECX-- до того как ECX = 0
	rep stosw

	ret

; ------------------------------------------------------------------

; Копировать буфер в VGA память
;
; Меняет: ECX, ESI, EDI
flush_buffer:
	mov ecx, 80*25*2/4		; Сколько dword
	mov esi, vga_buffer		; Откуда
	mov edi, VIDEO_MEMORY	; Куда
	rep movsd				; Копировать

	ret
	
; ------------------------------------------------------------------

; Переместить курсор в текущую позицию
;
; Меняет: EAX, ECX, EDX
cursor_to_pos:
	; Получить смещение в символах
	call get_pos_offset
	mov ecx, eax
	
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

; Отключить VGA мигание
;
; Меняет: EAX, EDX
disable_blink:
	mov dx, 0x3DA
	in al, dx

	mov dx, 0x3C0
	mov al, 0x10
	out dx, al

	mov al, 0x00
	out dx, al

	mov al, 0x20
	out dx, al
	
	ret
	
; ------------------------------------------------------------------
	
; Установить форму и видимость курсора
;
; Значение: AH
; Меняет: EAX, EDX, ECX
set_cursor:
	mov dx, 0x3D4
	mov al, 0xA
	out dx, al

	inc dx
	mov al, ah
	out dx, al

	ret

; ------------------------------------------------------------------

; Данные
section .data

; VGA атрибут (цвет) печати на экран
vga_attr db 0x07

; Координаты в символах печати на экран
pos_x db 0
pos_y db 0

; Неинициализированные данные
section .bss

; Буфер
vga_buffer resb 80*25*2