; ------------------------------------------------------------------
; Драйвер PS/2 мышки
; ------------------------------------------------------------------

; ISR мыши
mouse_stub:
	; Сохранить состояние
	pushad
	push ds

	; Установить сегменты
	mov ax, DATA_SEL
	mov ds, ax

	; Вызвать хендлер
	call mouse_handler

	; Отправить EOI Slave PIC и Master PIC
	mov al, PIC_EOI
	out PIC2, al
	out PIC1, al
	
	; Восстановить состояние
	pop ds
	popad

	iretd

; ------------------------------------------------------------------

; Хендлер мышки
mouse_handler:
	; Получить байт
	in al, 0x60

	; Индекс
	xor ebx, ebx
	mov bl, byte [mouse_packet_index]

	; Если не последний байт, сохранить байт
	cmp bl, 2
	jne .store

	; Сохранить байт и обработать пакет
	mov [mouse_packet + ebx], al
	mov byte [mouse_packet_index], 0
	; Проверка переполнения
	mov al, byte [mouse_packet]
	test al, 11000000b
	jnz .end
	; Состояние
	mov al, byte [mouse_packet]
	mov [mouse_state], al
	; ΔX
	movsx ax, byte [mouse_packet + 1]
	add [mouse_x], ax
	; ΔY
	movsx ax, byte [mouse_packet + 2]
	sub [mouse_y], ax ; Инверсия
	jmp .end
.store:
	; Сохранить байь и увеличить индекс
	mov [mouse_packet + ebx], al
	inc bl
	mov [mouse_packet_index], bl
.end:
	ret
.discard:
	mov byte [mouse_packet_index], 0
	ret

mouse_packet_index db 0
mouse_packet times 3 db 0
mouse_x dw 0
mouse_y dw 0
mouse_state db 0

; ------------------------------------------------------------------

MOUSE_RESOLUTION equ 2
MOUSE_SAMPLE_RATE equ 60

; Инициализация мышки
; 
; Меняет: AL, BL, ECX
mouse_init:
	; Команда включения Auxiliary Device
	call ps2_wait_wr
	mov al, 0xA8
	out 0x64, al

	; Включить IRQ12

	; Команда получения Compaq статуса
	call ps2_wait_wr
	mov al, 0x20
	out 0x64, al

	; Получить Compaq статус
	call ps2_wait_rd
	in al, 0x60
	
	; Включить бит 1 и выключить бит 5
	bts ax, 1
	btr ax, 5

	; Команда установки Compaq статуса
	mov bl, al
	call ps2_wait_wr
	mov al, 0x60
	out 0x64, al

	; Задать Compaq статус
	call ps2_wait_wr
	mov al, bl
	out 0x60, al

	; Настроить мышь
	
	; Команда сброса мыши
	mov ah, 0xFF
	call .ps2_mouse_wr
	; Self-Test
	call ps2_wait_rd
	in al, 0x60
	; ID
	call ps2_wait_rd
	in al, 0x60

	; Команда установки частоты
	mov ah, 0xF3
	call .ps2_mouse_wr
	; Частота
	mov ah, MOUSE_SAMPLE_RATE
	call .ps2_mouse_wr

	; Команда установки разрешения
	mov ah, 0xE8
	call .ps2_mouse_wr
	; Разрешение
	mov ah, MOUSE_RESOLUTION
	call .ps2_mouse_wr

	; Команда установки масштаба 1:1
	mov ah, 0xE6
	call .ps2_mouse_wr

	; Команда включения автоматической отправки пакетов
	mov ah, 0xF4
	call .ps2_mouse_wr

	ret

; Отослать команду/данные PS/2 мышке
.ps2_mouse_wr:
	; Сообщить то что команда/данные для мыши
	call ps2_wait_wr
	mov al, 0xD4
	out 0x64, al
	
	; Команда для мыши
	call ps2_wait_wr
	mov al, ah
	out 0x60, al

	; Проверить, отослала ли мышка ACK (0xFA)
	call ps2_wait_rd
	in al, 0x60
	cmp al, 0xFA
	jne .error

	ret
.error:
	mov esi, ps2_mouse_error_msg
	call println_str

	mov byte [key_queue_top], 0
	call wait_key
	mov byte [key_queue_top], 0

	ret

ps2_mouse_error_msg db 'PS/2 mouse initialization error', 0

; ------------------------------------------------------------------

; Подождать перед отсылкой команды контроллеру 8042 (порт 0x64/0x60)
ps2_wait_wr:
	mov ecx, 0xFFFF
.loop:
	in al, 0x64
	test al, 00000010b
	jz .done
	dec ecx
	jz .done
	jmp .loop
.done:
	ret

; Подождать перед чтением из контроллера 8042 (порт 0x60)
ps2_wait_rd:
	mov ecx, 0xFFFF
.loop:
	in al, 0x64
	test al, 00000001b
	jnz .done
	dec ecx
	jz .done
	jmp .loop
.done:
	ret