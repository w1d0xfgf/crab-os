; ------------------------------------------------------------------
; Менеджер памяти
; ------------------------------------------------------------------

bits 32

global mem_map_set
global mem_map_clear
global mem_map_test
global mem_map_set_region
global mem_free
global mem_alloc

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

; Освободить память
;
; Индекс: EBX
; Длина: ECX
; Меняет: EAX, EBX, ECX
mem_free:
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
	cmp eax, BITMAP_SIZE - 1
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

; Выделить память (непрерывный регион)
;
; Длина (в страницах): ECX
; Меняет: EAX, EBX, ECX, EDX, ESI
mem_alloc:
	test ecx, ecx
	jz .fail

	mov esi, ecx
	mov ebx, 0

.search_start:
	cmp ebx, BITMAP_SIZE
	jae .fail

	mov ecx, esi
	mov edx, ebx

.check_loop:
	mov eax, edx
	pushad
	call mem_map_test
	popad
	jnz .next_start

	inc edx
	dec ecx
	jnz .check_loop

	mov ebx, ebx
	mov ecx, esi
	call mem_map_set_region

	clc
	ret

.next_start:
	inc ebx
	jmp .search_start

.fail:
	stc
	ret


; ------------------------------------------------------------------

; Неинициализированные данные
section .bss

; Bitmap для хранения состояния (занато/свободно) страниц (4096 Б на каждую) памяти
bitmap resb BITMAP_SIZE/8