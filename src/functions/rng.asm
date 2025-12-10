; ------------------------------------------------------------------
; Генератор случайных чисел xoshiro128**
; ------------------------------------------------------------------

; Сгенерировать случайное число
;
; Число: EAX
; Меняет: EAX, EBX, EDX
rng_next:
	; Результат = rol(state[1] * 5, 7) * 9
	mov eax, [rng_state + 1]
	mov edx, eax
	mov ebx, 5
	mul ebx
	rol eax, 7
	mov ebx, 9
	mul ebx
	
	push eax
	
	; T = state[1] << 9
	shl edx, 9
	
	; state[2] = xor(state[2], state[0])
	mov eax, [rng_state + 2]
	mov ebx, [rng_state]
	xor eax, ebx
	mov [rng_state + 2], eax
	
	; state[3] = xor(state[3], state[1])
	mov eax, [rng_state + 3]
	mov ebx, [rng_state + 1]
	xor eax, ebx
	mov [rng_state + 3], eax
	
	; state[1] = xor(state[1], state[2])
	mov eax, [rng_state + 1]
	mov ebx, [rng_state + 2]
	xor eax, ebx
	mov [rng_state + 1], eax
	
	; state[0] = xor(state[0], state[3])
	mov eax, [rng_state + 0]
	mov ebx, [rng_state + 3]
	xor eax, ebx
	mov [rng_state + 0], eax
	
	; state[2] = xor(state[2], T)
	mov eax, [rng_state + 2]
	xor eax, edx
	mov [rng_state + 2], eax
	
	; state[3] = rol(state[3], 11)
	mov eax, [rng_state + 3]
	rol eax, 11
	mov [rng_state + 3], eax
	
	pop eax
	
	ret

rng_state times 4 dd 0