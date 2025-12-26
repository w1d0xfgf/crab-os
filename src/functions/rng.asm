; ------------------------------------------------------------------
; Генератор случайных чисел xoshiro128**
; ------------------------------------------------------------------

; Сгенерировать случайное число и обновить состояние
;
; Число: EAX
; Меняет: EAX, EBX, EDX
rng_next:
	; Результат = rol(state[1] * 5, 7) * 9
	mov eax, [rng_state + 4]
	mov ebx, 5
	mul ebx
	rol eax, 7
	mov ebx, 9
	mul ebx
	
	; Сохранить результат
	push eax
	
	; Адрес = Начало массива + индекс * байтов на элемент
	; Double Word - 4 байта

	; state[2] = xor(state[2], state[0])
	mov eax, [rng_state + 8]
	mov ebx, [rng_state]
	xor eax, ebx
	mov [rng_state + 8], eax
	
	; state[3] = xor(state[3], state[1])
	mov eax, [rng_state + 12]
	mov ebx, [rng_state + 4]
	xor eax, ebx
	mov [rng_state + 12], eax
	
	; state[1] = xor(state[1], state[2])
	mov eax, [rng_state + 4]
	mov ebx, [rng_state + 8]
	xor eax, ebx
	mov [rng_state + 4], eax
	
	; state[0] = xor(state[0], state[3])
	mov eax, [rng_state + 0]
	mov ebx, [rng_state + 12]
	xor eax, ebx
	mov [rng_state + 0], eax
	
	; state[2] = xor(state[2], state[1] << 9)
	mov edx, [rng_state + 1]
	shl edx, 9
	mov eax, [rng_state + 8]
	xor eax, edx
	mov [rng_state + 8], eax
	
	; state[3] = rol(state[3], 11)
	mov eax, [rng_state + 12]
	rol eax, 11
	mov [rng_state + 12], eax

	; Вернуть результат
	pop eax
	
	ret

; ------------------------------------------------------------------

; Сделать состояние PRNG из одного 32-битного сида
; 
; Сид: EAX
seed_rng:
	; state[0]
	call .splitmix32
	mov [rng_state], eax

	; state[1]
	call .splitmix32
	mov [rng_state + 4], eax

	; state[2]
	call .splitmix32
	mov [rng_state + 8], eax

	; state[3]
	call .splitmix32
	mov [rng_state + 12], eax

	ret
.splitmix32:
	add eax, 0x9E3779B9

	; EAX = (EAX ^ (EAX >> 16)) * 0x85EBCA6B
	mov edx, eax
	shl edx, 16
	xor eax, edx
	mov edx, 0x85EBCA6B
	mul edx

	; EAX = (EAX ^ (EAX >> 13)) * 0xC2B2AE35
	mov edx, eax
	shl edx, 13
	xor eax, edx
	mov edx, 0xC2B2AE35
	mul edx

	; EAX = EAX ^ (EAX >> 16)
	mov edx, eax
	shl edx, 16
	xor eax, edx

	ret

; ------------------------------------------------------------------

; Состояние RNG: 4 dword (32-битных числа)
rng_state:
	dd 0x1234
	dd 0xB00B
	dd 0xDEAD
	dd 0xBEEF