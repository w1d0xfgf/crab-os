; ------------------------------------------------------------------
; Функции для работы со строками
; ------------------------------------------------------------------

; Сравнение двух строк
; 
; Адресы строк: ESI, EDI
; Меняет: EAX, ECX
compare_strs:
	mov edx, 1			; Равны = true
	xor ecx, ecx 		; Индекс (ECX) = 0
.loop:
	mov al, [esi + ecx]	; Загрузить символ 1
	mov ah, [edi + ecx]	; Загрузить символ 2
	
	; Сравнить
	cmp al, ah
	jne .not_equal
	
	; Если символы 0 (NULL terminator - конец строки), выйти 
	cmp al, 0
	je .done
	
	; Следующий символ
	inc ecx
	jmp .loop
.not_equal:
	; Если символы не равны, равны = false и выйти
	mov edx, 0	
.done:
	ret
	
; ------------------------------------------------------------------

; Запись значения EAX в шестнадцатеричном формате в строку
;
; Адрес строки: EDI
; Меняет: AL, EBX, ECX, EDI	
hex_str_from_eax:
    mov esi, hex_str		; Адрес hex_str
	mov ecx, 8 				; Количество символов
.loop:
    rol eax, 4				; Смещение EAX вправо на 4, последняя 16-ичная цифра будет первой
    mov ebx, eax			; Копия EAX -> EBX
    and ebx, 0x0F			; Оставить последнюю 16-ичную цифру
    mov bl, [esi + ebx]		; Получение символа: hex_str[EBX]	
    mov [edi], bl			; Запись символа в строку
	
	; Следующая итерация
    inc edi					; Следующий символ в строке
    dec ecx					; Следующая цифра
    jnz .loop
	
    ret
	
; ------------------------------------------------------------------

; Запись значения AL в шестнадцатеричном формате в строку
;
; Адрес строки: EDI
; Меняет: AL, EBX, ECX, EDI	
hex_str_from_al:
    mov esi, hex_str		; Адрес hex_str
	mov ecx, 2 				; Счётчик
	; Если не обнулить EBX, в битах 32-8 будут другие значения и они будут мешать
	xor ebx, ebx				
.loop:
	rol al, 4				; Смещение EAX вправо на 4, последняя 16-ичная цифра будет первой
    mov bl, al				; Копия AL -> BL
    and bl, 0x0F			; Оставить последнюю 16-ичную цифру
    mov bl, [esi + ebx]		; Получение символа: hex_str[EBX]	
    mov [edi], bl			; Запись символа в строку по адресу EDI
	
	; Следующая итерация 
	inc edi
	dec ecx
	jnz .loop
	
	ret
	
; ------------------------------------------------------------------

; Убрать все ведущие и хвостовые пробелы, \n и \r
; К примеру: '  hello\n  ' -> 'hello'
;
; Адрес входной строки: ESI
; Адрес выходной строки: EDI
trim_str:

; Найти начало чистой строки
.leading:
	; Загрузить символ, если NULL (конец строки) пропустить всё
    mov al, [esi]
	cmp al, 0
    je .empty

	; Если символ пробел, \n, или \r, переход к следующему
    cmp al, ' '
    je .leading_next
    cmp al, 13
    je .leading_next
    cmp al, 10
    je .leading_next

	; Иначе, закончить цикл
    jmp .leading_done
.leading_next:
    inc esi
    jmp .leading
.leading_done:
	; Адрес начала чистой строки
    mov ebx, esi

; Найти конец строки
.find_end:
	; Загрузить символ
    mov al, [esi]

	; Если символ NULL -- конец строки
    cmp al, 0
    je .end_found

	; Иначе, повторить
    inc esi
    jmp .find_end
; Если нашёлся конец
.end_found:
    mov edx, esi         ; EDX = Адрес конца (символа NULL terminator)
    dec edx              ; EDX = Адрес последнего реального символа
    cmp edx, ebx
    jb .empty            ; Если длина 0

; Найти конец чистой строки
.trailing:
	; Загрузить символ
    mov al, [edx]

	; Если символ пробел, \n, или \r, переход к следующему
    cmp al, ' '
    je .trailing_next
    cmp al, 13
    je .trailing_next
    cmp al, 10
    je .trailing_next

	; Иначе, закончить цикл
    jmp .copy
.trailing_next:
	; Если строка
    dec edx
    cmp edx, ebx
    jae .trailing

	; Если 
    jmp .empty

; Копия результата
.copy:
    inc edx                 ; сделать EDX на 1 дальше, чтобы ECX = длина
    mov ecx, edx
    sub ecx, ebx            ; длина trimmed строки
    mov esi, ebx            ; источник = начало trimmed

    rep movsb               ; копирование

    mov byte [edi], 0       ; завершить нулём
    ret

; Если строка пустая
.empty:
    mov byte [edi], 0
    ret