; ------------------------------------------------------------------
; Функции для работы со строками
; ------------------------------------------------------------------

; Сравнение двух строк
; 
; Адресы строк: ESI, EDI
; Меняет: EAX, ECX, EDX
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
; Меняет: EAX, EBX, ECX, EDI	
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
; Меняет: EAX, EBX, ECX, EDI	
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

hex_str db '0123456789ABCDEF'

; ------------------------------------------------------------------

; Запись значения EAX в шестнадцатеричном формате в строку
;
; Адрес строки: EDI
; Меняет: EAX, EBX, ECX, EDI	
str_from_eax:
	push edi

	; Очистить буфер
	push eax
	mov ecx, 10
	mov edi, str_from_eax_buffer
	mov al, ' '
.clear:
	mov [edi], al
	inc edi
	dec ecx
	jnz .clear
	pop eax

	mov edi, str_from_eax_buffer + 9
.loop:
	; Если EAX = 0, конец
	test eax, eax
	jz .done

	; Получить последнюю цифру EAX (EAX /= 10)
	xor edx, edx
	mov ecx, 10
	div ecx

	; Код символа = Код символа '0' + Полученная цифра
	add edx, '0'
	mov [edi], dl

	; Следующая итерация
	dec edi
	jmp .loop
.done:
	; Обрезать лишние пробелы
	mov esi, str_from_eax_buffer
	pop edi
	call trim_str
	
	ret
str_from_eax_buffer:
	times 10 db ' '
	db 0
	
; ------------------------------------------------------------------

; Убрать все ведущие и хвостовые пробелы, \n и \r
; К примеру: '  hello\n  ' -> 'hello'
;
; Адрес входной строки: ESI
; Адрес выходной строки: EDI
; Меняет: EAX, EBX, ECX, EDX, ESI, EDI
trim_str:
; Найти начало чистой строки
.leading:
	mov al, [esi]	; Загрузить символ в AL
	cmp al, 0		; Если символ NULL (конец строки), чистая строка пустая
	je .empty		; Пропустить всё

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
	inc esi			; Следующий символ
	jmp .leading	; Повторить цикл
.leading_done:
	; Адрес начала чистой строки
	mov ebx, esi

; Найти конец строки
.find_end:
	mov al, [esi]	; Загрузить символ в AL

	cmp al, 0		; Если символ NULL, конец строки
	je .end_found	; Конец цикла (конец найден)

	inc esi			; Следующий символ
	jmp .find_end	; Повторить цикл
.end_found:
	mov edx, esi	; EDX = Адрес конца (символа NULL terminator)
	dec edx			; EDX = Адрес последнего реального символа
	cmp edx, ebx
	jb .empty		; Если длина 0

; Найти конец чистой строки
.trailing:
	mov al, [edx]	; Загрузить символ в AL

	; Если символ пробел, \n, или \r, переход к следующему
	cmp al, ' '
	je .trailing_next
	cmp al, 13
	je .trailing_next
	cmp al, 10
	je .trailing_next

	; Закончить цикл
	jmp .copy
.trailing_next:
	; Следующий символ
	dec edx
	cmp edx, ebx
	jae .trailing

	; Если конец = начало, строка пустая
	jmp .empty

; Копия чистой строки в место назначения
.copy:
	inc edx				; Сделать EDX на 1 дальше, чтобы ECX = длина
	mov ecx, edx
	sub ecx, ebx		; Длина чистой строки
	mov esi, ebx		; Источник = начало чистой строки

	rep movsb			; Копирование

	mov byte [edi], 0	; Завершить NULL (обязательно)
	ret

; Если строка пустая
.empty:
	mov byte [edi], 0
	ret