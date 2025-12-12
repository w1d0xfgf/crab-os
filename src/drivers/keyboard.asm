; ------------------------------------------------------------------
; Драйвер клавиатуры
; ------------------------------------------------------------------

; Ожидать нажатия клавиши и выдать scancode
;
; Scancode: EBX
wait_key:
	movzx ebx, byte [key_queue_top]		; Проверить есть ли в очереди клавиши
	cmp ebx, 0							; 
	je wait_key						    ; Если нет, повторить

    ret

; Хендлер клавиатуры
keyboard_handler:
	; Scancode
    in al, 0x60
    movzx ebx, al
	
	; Проверка на E0
    cmp al, 0xE0
    je .prefix_E0

    ; Break?
    test al, 0x80
    jnz .key_release
.key_press:
    ; Обычная клавиша
    cmp byte [prev_E0], 1
    jne .store_normal_press
	
    ; Расширенная клавиша
    mov byte [prev_E0], 0
    or bl, 0x80
.store_normal_press:
    ; Установить статус соответствующей сканкоду клавиши: нажато
    mov byte [keys_pressed + ebx], 1
	
	; Очередь
	movzx eax, byte [key_queue_top]     ; индекс
	mov [key_queue + eax], bl   	 	; записать scancode
	inc byte [key_queue_top]     		; увеличить индекс
	
    jmp .end
.key_release:
	; Перевод в make code
    and al, 0x7F      
    movzx ebx, al
	
	; Обычная клавиша
    cmp byte [prev_E0], 1
    jne .store_normal_release
	
	; Расширенная клавиша
    mov byte [prev_E0], 0
    or bl, 0x80       
.store_normal_release:
    ; Установить статус соответствующей сканкоду клавиши: не нажато
    mov byte [keys_pressed + ebx], 0
    jmp .end
.prefix_E0:
    mov byte [prev_E0], 1
.end:
    ret

key_queue times 64 db 0			; Очередь для нажатых клавиш
key_queue_top db 0				; Указатель на вершину очереди
keys_pressed times 256 db 0		; Нажатые в данный момент клавиши
prev_E0 db 0					; Является ли клавиша расширенной или обычной