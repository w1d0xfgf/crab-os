; ------------------------------------------------------------------
; Менеджер памяти
; ------------------------------------------------------------------

bits 32

global mem_map_set
global mem_map_clear
global mem_map_test
global mem_map_set_region
global mem_map_clear_region
global mem_map_first_free

; Размер Bitmap в страницах
BITMAP_SIZE equ 4096

; ------------------------------------------------------------------

; Код
section .text

; Сделать бит в Bitmap 1
;
; Бит: EAX
; Меняет: EAX, EBX, ECX
mem_map_set:
	; EBX = EAX / 8
	mov ebx, eax
	shr ebx, 3

	; AL = 1 << (EAX % 8)
	and eax, 00000111b
	mov cl, al
	mov al, 1
	shl al, cl

	; BITMAP[EBX] |= AL
	or byte [bitmap + ebx], al

	ret

; ------------------------------------------------------------------

; Сделать бит в Bitmap 0
;
; Бит: EAX
; Меняет: EAX, EBX, ECX
mem_map_clear:
	; EBX = EAX / 8
	mov ebx, eax
	shr ebx, 3

	; AL = ~(1 << (EAX % 8))
	and eax, 00000111b
	mov cl, al
	mov al, 1
	shl al, cl
	not al

	; BITMAP[EBX] &= AL
	and byte [bitmap + ebx], al

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

	; AL = 1 << (EAX % 8)
	and eax, 00000111b
	mov cl, al
	mov al, 1
	shl al, cl

	; EDX = BITMAP[EBX] & EAX
	movzx edx, byte [bitmap + ebx]
	and edx, eax

	; Установить флаги
	test edx, edx

	ret

; ------------------------------------------------------------------

; Сделать биты определённого региона (индекс и длина) 0
;
; Индекс: EBX
; Длина: ECX
; Меняет: EAX, EBX, ECX
mem_map_clear_region:
	; Пропустить если длина 0
	test ecx, ecx
	jz .end

.loop:
	push ebx
	push ecx
	mov eax, ebx
	cmp eax, BITMAP_SIZE - 1
	jae .error
	call mem_map_clear
	pop ecx
	pop ebx
	
	inc ebx
	dec ecx
	jnz .loop
	jmp .end
.error:
	pop ecx
	pop ebx
.end:
	ret

; ------------------------------------------------------------------

; Сделать биты определённого региона (индекс и длина) 1
;
; Индекс: EBX
; Длина: ECX
; Меняет: EAX, EBX, ECX
mem_map_set_region:
	; Пропустить если длина 0
	test ecx, ecx
	jz .end

.loop:
	push ebx
	push ecx
	mov eax, ebx
	cmp eax, BITMAP_SIZE/8 - 1
	jae .error
	call mem_map_set
	pop ecx
	pop ebx
	
	inc ebx
	dec ecx
	jnz .loop
	jmp .end
.error:
	pop ecx
	pop ebx
.end:
	ret

; ------------------------------------------------------------------

; Найти первый свободный бит в Bitmap (если нет, CF)
;
; Индекс бита: EBX
; Меняет: EAX, EBX, ECX, EDX
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
	cmp ebx, BITMAP_SIZE/8
	jb find_byte

	stc
	ret
found_bit:
	shl ebx, 3
	add ebx, ecx

	clc
	ret

; ------------------------------------------------------------------

; Неинициализированные данные
section .bss

; Bitmap для хранения состояния (занато/свободно) страниц (4096 Б на каждую) памяти
bitmap resb BITMAP_SIZE/8