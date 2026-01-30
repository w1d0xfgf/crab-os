bits 32

extern ramchk_cmd
extern version_cmd
extern mouse_cmd
extern beep_cmd
extern memv_cmd
extern cls_cmd
extern pit_cmd
extern pong_cmd
extern fib_cmd
extern help_cmd
extern rand_cmd
extern info_cmd
extern panic_cmd
extern restart_cmd
extern init_gui
extern update_gui
extern get_rtc_time
extern seed_rng
extern flush_buffer
extern print_char
extern print_str
extern cursor_to_pos

extern vga_attr
extern pos_x
extern pos_y
extern scancode_to_ascii
extern scancode_to_ascii_shift
extern key_queue_top
extern keys_pressed
extern compare_strs
extern trim_str
extern key_queue

global os_entry

; Код
section .text

; Запуск
os_entry:
	; Инициализизовать GUI
	call init_gui

	; Сдлеать state PRNG из времени
	call get_rtc_time
	; Байты EAX: Секунды, Минуты, Часы, Дни
	mov ax, bx
	shl eax, 16
	mov ax, cx
	call seed_rng

; Цикл программы
event_loop:
	; Обновление GUI
	call update_gui
	mov byte [vga_attr], 0x07
	call flush_buffer
	
	; Обработка нажатия клавиши
.handle_key:
	; Проверить есть ли в очереди клавиши, если нет, не обрабатывать
	movzx ebx, byte [key_queue_top]		
	test ebx, ebx
	jz .skip_key
	
	; Scancode
	dec ebx								; EBX = Индекс верхнего элемента
	movzx eax, byte [key_queue + ebx]	; Scancode

	; Сохранить Scancode
	push ax

	cmp al, 0x7F
	jae .non_printable

	; Проверка на левый и правый Shift
	cmp byte [keys_pressed + 0x2A], 1
	je .shift_pressed
	cmp byte [keys_pressed + 0x36], 1
	je .shift_pressed

	; Непечатаемые символы
	cmp al, 0x7F
	jae .non_printable

	; Если Shift не нажат, обычная таблица Scancode -> ASCII
	mov al, [scancode_to_ascii + eax]
	jmp .converted
.shift_pressed:
	; Если Shift нажат, другая таблица Scancode -> ASCII
	mov al, [scancode_to_ascii_shift + eax]
.converted:
	; Непечатаемые символы
	test al, al
	jz .non_printable
	
	; Убрать scancode со стека
	add esp, 2

	; Проверить, заполнен ли user_input (user_input_top >= длина - 1)
	cmp byte [user_input_top], USER_INPUT_SIZE_BYTES - 1
	jae .finished_key

	; Сохранить символ в user_input
	movzx ebx, byte [user_input_top]
	mov [user_input + ebx], al
	inc byte [user_input_top]
	
	; Печать
	call print_char

	; Обновить позицию курсора
	call cursor_to_pos
	
	jmp .finished_key
.non_printable:
	; Получить scancode
	pop ax
	
	; Backspace
	cmp al, 0x0E
	je .backspace
	
	; Enter
	cmp al, 0x1C
	jne .finished_key
	cmp byte [user_input_top], 0
	je .finished_key
	call input_done
.finished_key:
	cmp byte [key_queue_top], 0
	je .skip_key

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
	dec byte [user_input_top]
	movzx ebx, byte [user_input_top]
	mov byte [user_input + ebx], 0

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
	call update_gui
	mov byte [vga_attr], 0x07
	call flush_buffer

	; Если ввод пустой, пропустить обработку
	cmp byte [user_input_top], 0
	je .end

	; Обрезать лишние пробелы, \n и \r
	mov esi, user_input
	mov edi, user_input_trimmed
	call trim_str	
	
	; Сохранить позицию
	mov al, [pos_x]
	mov ah, [pos_y]
	push ax

	mov byte [pos_x], 0
	mov byte [pos_y], 2
	
	; Команда panic
	command panic_cmd_str
	je panic_cmd
.cmp2:
	; Команда restart
	command restart_cmd_str
	je restart_cmd
.cmp3:
	; Команда info
	command info_cmd_str
	jne .cmp4
	call info_cmd
	jmp .end
.cmp4:
	; Команда rand
	command rand_cmd_str
	jne .cmp5
	call rand_cmd
	jmp .end
.cmp5:
	; Команда help
	command help_cmd_str
	jne .cmp6
	call help_cmd
	jmp .end
.cmp6:
	; Команда pong
	command pong_cmd_str
	jne .cmp7
	call pong_cmd
	jmp .end
.cmp7:
	; Команда pit
	command pit_cmd_str
	jne .cmp8
	call pit_cmd
	jmp .end
.cmp8:
	; Команда cls
	command cls_cmd_str
	jne .cmp9
	call cls_cmd
	jmp .end
.cmp9:
	; Команда memv
	command memv_cmd_str
	jne .cmp10
	call memv_cmd
	jmp .end
.cmp10:
	; Команда beep
	command beep_cmd_str
	jne .cmp11
	call beep_cmd
	jmp .end
.cmp11:
	; Команда mouse
	command mouse_cmd_str
	jne .cmp12
	call mouse_cmd
	jmp .end
.cmp12:
	; Команда version
	command version_cmd_str
	jne .cmp13
	call version_cmd
	jmp .end
.cmp13:
	; Команда ramchk
	command ramchk_cmd_str
	jne .cmp14
	call ramchk_cmd
	jmp .end
.cmp14:
	; Команда fib
	command fib_cmd_str
	jne .fail
	call fib_cmd
	jmp .end
.fail:
	; Вывести invalid_cmd_msg на экран
	mov byte [vga_attr], 0x0C		; Ярко-красный
	mov byte [pos_x], 0				; Под командной строкой
	mov byte [pos_y], 2				;
	mov esi, invalid_cmd_msg		; Сообщение
	call print_str					; Печать
	mov byte [vga_attr], 0x07		; Вернуть цвет
.end:
	; Сбросить ввод
	call reset_user_input
	
	; Восстановить позицию
	pop ax
	mov [pos_y], ah
	mov [pos_x], al
.ret:
	ret

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
	cmp ecx, USER_INPUT_SIZE_BYTES
	jb .loop
	
	ret

; ------------------------------------------------------------------

; Данные
section .data

; Размер строки ввода в байтах
USER_INPUT_SIZE_BYTES equ 32

; Строка которую ввёл пользователь
user_input: times USER_INPUT_SIZE_BYTES db 0
user_input_top: db 0

; Обрезанная строка (без лишних пробелов, \n и \r)
user_input_trimmed: times USER_INPUT_SIZE_BYTES db 0

invalid_cmd_msg:
	db 'Invalid command.', 13, 10
	db 'Type "help" for a list of commands.', 0

; Команды
ramchk_cmd_str db 'ramchk', 0
version_cmd_str db 'version', 0
mouse_cmd_str db 'mouse', 0
beep_cmd_str db 'beep', 0
memv_cmd_str db 'memv', 0
cls_cmd_str db 'cls', 0
pit_cmd_str db 'pit', 0
pong_cmd_str db 'pong', 0
fib_cmd_str db 'fib', 0
help_cmd_str db 'help', 0
rand_cmd_str db 'rand', 0
info_cmd_str db 'info', 0
panic_cmd_str db 'panic', 0
restart_cmd_str db 'restart', 0