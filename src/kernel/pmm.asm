; ------------------------------------------------------------------
; Менеджер памяти
; ------------------------------------------------------------------

bits 32

; Размер Bitmap в страницах
BITMAP_SIZE equ 1028

; ------------------------------------------------------------------

; Код
section .text

; Сделать бит в Bitmap 1
;
; Бит: EAX
; Меняет: EBX, ECX
mem_map_set:
	; EBX = EAX / 8
	mov ebx, eax
	shr ebx, 3

	; ECX = 1 << (EAX % 8)
	and eax, 00000111b
	mov ecx, 1
	shl ecx, eax

	; BITMAP[EBX] |= ECX
	or byte [bitmap + ebx], ecx

	ret

; ------------------------------------------------------------------

; Сделать бит в Bitmap 0
;
; Бит: EAX
; Меняет: EBX, ECX
mem_map_clear:
	; EBX = EAX / 8
	mov ebx, eax
	shr ebx, 3

	; ECX = ~(1 << (EAX % 8))
	and eax, 00000111b
	mov ecx, 1
	shl ecx, eax
	not ecx

	; BITMAP[EBX] &= ECX
	and byte [bitmap + ebx], ecx

	ret

; ------------------------------------------------------------------

; Проверить бит в Bitmap
;
; Бит: EAX
; Результат: EFLAGS
; Меняет: EBX, ECX
mem_map_test:
	; EBX = EAX / 8
	mov ebx, eax
	shr ebx, 3

	; ECX = 1 << (EAX % 8)
	and eax, 00000111b
	mov ecx, 1
	shl ecx, eax

	; EDX = BITMAP[EBX] & ECX
	mov edx, byte [bitmap + ebx]
	and edx, ecx

	; Установить флаги
	test edx, edx

	ret

; ------------------------------------------------------------------

; Сделать биты определённого региона (базовый индекс и длина) 0
;
; Базовый индекс: EBX
; Длина: ECX
mem_map_clear_region:
	push ebx
	push ecx
	mov eax, ebx
	call mem_map_clear
	pop ecx
	pop ebx
	
	dec ecx
	jnz mem_map_clear_region

	ret

; ------------------------------------------------------------------

; Сделать биты определённого региона (базовый индекс и длина) 1
;
; Базовый индекс: EBX
; Длина: ECX
mem_map_set_region:
	push ebx
	push ecx
	mov eax, ebx
	call mem_map_set
	pop ecx
	pop ebx
	
	dec ecx
	jnz mem_map_set_region

	ret

; ------------------------------------------------------------------

; Найти первый свободный бит в Bitmap
;
; Индекс бита: EBX (если нет, -1)
; Меняет: EAX, ECX, EDX
mem_map_first_free:
    mov ebx, 0
find_byte:
    mov al, [bitmap + ebx]
    cmp al, 0xFF
    je next_byte
    mov ecx, 0
find_bit_in_byte:
    mov edx, 1
    shl edx, cl
    test al, dl
    jz found_bit
    inc ecx
    cmp ecx, 8
    jb find_bit_in_byte
next_byte:
    inc ebx
    cmp ebx, BITMAP_SIZE
    jb find_byte
    mov ebx, -1
    ret
found_bit:
    shl ebx, 3
    add ebx, ecx

    ret

; ------------------------------------------------------------------

; Неинициализированные данные
section .bss

; Bitmap для хранения состояния (занато/свободно) страниц (4096 Б на каждую) памяти
bitmap resb BITMAP_SIZE/8