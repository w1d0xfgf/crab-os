; Запуск
startup:
    ; PRNG
	call get_rtc_time
	; Первые 2 байта State[0] = 0xMMSS (M -- минуты, S -- секунды)
	mov word [rng_state], bx	
	; Вторые 2 байта State[0] = 0xDDHH (D -- дни, H -- часы)
	mov word [rng_state + 2], cx

    ; Инициализизовать GUI
	call init_gui

; Цикл программы
event_loop:
	; Обновление GUI
	call update_gui
	mov byte [attr], 0x07

    ; Ожидание клавиши
    call wait_key
		
	; Обработка нажатия клавиши
.handle_key:
	movzx ebx, byte [key_queue_top]		; Проверить есть ли в очереди клавиши
	cmp ebx, 0							; 
	je .skip_key						; Пропустить обработку клавиши если очередь пустая

	; Проверить, заполнен ли user_input (user_input_top >= длина - 1)
	cmp byte [user_input_top], 31
	jae .skip_key
	
	; Scancode
	dec ebx								; EBX = Индекс верхнего элемента
	movzx ax, byte [key_queue + ebx]	; Scancode
	
	; Символ
	push ax
	mov al, [scancode_to_ascii + eax]
	test al, al
	jz .non_ascii
	
	; Печать
	call print_char
	
	; Сохранить символ в user_input
	movzx ebx, byte [user_input_top]
	mov [user_input + ebx], al
	inc byte [user_input_top]
	
	; Обновить позицию курсора
	call cursor_to_pos
	
	jmp .finished_key
.non_ascii:
	pop ax
	
	; Backspace
	cmp ax, 0x0E
	je .backspace
	
	; Enter
	cmp ax, 0x1C
	jne .finished_key
	call input_done
.finished_key:
	; Убрать элемент после того как он был обработан
	dec byte [key_queue_top]	
	jmp .skip_key
.backspace:
	; Если нету символов, пропустить
	cmp byte [user_input_top], 0		
	je .finished_key
	
	dec byte [pos_x]	; Уменьшить позицию по X
	mov ah, [pos_x]		; Сохранить позицию
	mov al, 0x20		; Пробел
	call print_char		;
	mov [pos_x], ah		; Вернуть позицию
	call cursor_to_pos	; Обновить позицию курсора

	; Обновить строку ввода
	movzx ebx, byte [user_input_top]
	mov byte [user_input + ebx], 0
	dec byte [user_input_top]

	jmp .finished_key 
.skip_key:
    jmp event_loop	
	
; ------------------------------------------------------------------

; Макрос для команд
%macro command 1
	; Сравнить строки
	mov esi, user_input_trimmed
	mov edi, %1
	call compare_strs
	cmp edx, 1
%endmacro

input_done:
	; Сбросить GUI
	call init_gui

	; Если ввод пустой, пропустить обработку
	cmp byte [user_input], 0	; Первый байт в пустой строке -- NULL
	je .ret

	; Обрезать лишние пробелы, \n и \r
	mov esi, user_input
	mov edi, user_input_trimmed
	call trim_str	
	
	; Сохранить позицию
	mov al, [pos_x]
	mov ah, [pos_y]
	push ax
	
	; Команда panic
	command panic_cmd_str
	je panic_cmd
.cmp2:
	; Команда restart
	command restart_cmd_str
	je restart_cmd
.cmp3:
	; Команда ping
	command ping_cmd_str
	jne .cmp4
	call ping_cmd
	jmp .end
.cmp4:
	; Команда rand
	command rand_cmd_str
	jne .cmp5
	call rand_cmd
	jmp .end
.cmp5:
	; Команда rand
	command help_cmd_str
	jne .fail
	call help_cmd
	jmp .end
.fail:
	; Вывести invalid_cmd_msg на экран
	mov byte [attr], 0x0C		; Ярко-красный
	mov byte [pos_x], 0			; Под командной строкой
	mov byte [pos_y], 2			;
	mov esi, invalid_cmd_msg	; Сообщение
	call print_str				; Печать
	mov byte [attr], 0x07		; Вернуть цвет
.end:
	; Сбросить ввод
	call reset_user_input
	
	; Восстановить позицию
	pop ax
	mov [pos_y], ah
	mov [pos_x], al
.ret:
	ret
invalid_cmd_msg:
	db 'Invalid command.', 13, 10
	db 'Type "help" for a list of commands.', 0

; Команды
%include "src/os/cmd.asm"

; ------------------------------------------------------------------

; Функция для очистки строки ввода пользователя
;
; Меняет: ECX
reset_user_input:
	mov ecx, 0
	mov byte [user_input_top], 0
.loop:
	mov byte [user_input + ecx], 0

	inc ecx
	cmp ecx, 64
	jb .loop
	
	ret

; ------------------------------------------------------------------

; GUI
%include "src/os/gui.asm"

; PRNG (xoshiro128**)
%include "src/functions/rng.asm"

; ------------------------------------------------------------------

; Строка которую ввёл пользователь
user_input: times 32 db 0
user_input_top: db 0

; Обрезанная строка (без лишних пробелов, \n и \r)
user_input_trimmed: times 32 db 0