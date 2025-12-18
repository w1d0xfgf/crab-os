; ------------------------------------------------------------------
; Команды в консоли
; ------------------------------------------------------------------

; Версия ОС
version_cmd:
	mov esi, version_str
	mov byte [pos_x], 0
	mov byte [pos_y], 2
	call print_str

	ret
version_cmd_str db 'version', 0
version_str db 'v0.1.5', 0

; Тест мышки
mouse_cmd:
	%include "src/os/cmd/mouse.asm"
mouse_cmd_str db 'mouse', 0

; Бип
beep_cmd:
	; Включить звук с частотой 1500 Гц
	mov ecx, 1500
	call play_sound

	; Подождать 100 тиков
	mov edx, 100
	call sleep_ticks

	; Выключить звук
	call stop_sound
	
	ret
beep_cmd_str db 'beep', 0

; Просмотреть память
memv_cmd:
	%include "src/os/cmd/memv.asm"
memv_cmd_str db 'memv', 0

; Очистить экран
cls_cmd:
	call init_gui

	ret
cls_cmd_str db 'cls', 0

; Вывести тики PIT на экран
pit_cmd:
	mov eax, [system_timer_ticks]
	mov [reg32], eax
	mov byte [pos_x], 0
	mov byte [pos_y], 2
	call print_reg32

	ret
pit_cmd_str db 'pit', 0

; Игра Pong
pong_cmd:
	%include "src/os/pong.asm"
pong_cmd_str db 'pong', 0
p1_paddle_pos db 0			; Позиция ракетки игрока 1
p2_paddle_pos db 0			; Позиция ракетки игрока 2
p1_paddle_pos_prev db 0		; Предыдущая позиция ракетки игрока 1
p2_paddle_pos_prev db 0		; Предыдущая позиция ракетки игрока 2
ball_pos_x db 0				; Позиция мячика
ball_pos_y db 0				;
ball_pos_x_prev db 0		; Предыдущая позиция мячика
ball_pos_y_prev db 0		;
ball_dir db 0 				; Направление мячика: 0 - влево вверх, 1 - вправо вверх, 2 - влево вниз, 3 - вправо вниз
last_update_ticks dd 0
p1_won_msg db 'Player 1 won!', 0
p2_won_msg db 'Player 2 won!', 0
key_press_msg db 'Press any key...', 0

; Вывод следующего числа фибоначчи в формате "0xXXXXXXXX"
fib_cmd:
	; "0x"
	mov byte [pos_x], 0
	mov byte [pos_y], 2
	mov al, '0'
	call print_char
	mov al, 'x'
	call print_char
	
	; F2 = F1 + F0
	mov eax, [fib_f0]
	add eax, [fib_f1]

	; Если произошло переполнение сбросить F1 и F0
	jc .reset

	; F0 = F1
	mov edx, [fib_f1]
	mov [fib_f0], edx

	; F1 = F2
	mov [fib_f1], eax

	; Печать
	mov [reg32], eax
	call print_reg32
	
	ret
.reset:
	; Сброс
	mov dword [fib_f0], 1
	mov dword [fib_f1], 1

	; Посчитать число
	jmp fib_cmd
fib_cmd_str db 'fib', 0
fib_f1 dd 1
fib_f0 dd 1

; Вывод списка команд
help_cmd:
	mov esi, cmd_list_msg
	mov byte [pos_x], 0
	mov byte [pos_y], 2
	call print_str
	
	ret
help_cmd_str db 'help', 0
cmd_list_msg:
	db 'Commands:', 13, 10
	db 'beep    - Make a beep', 13, 10
	db 'cls     - Clear the screen and re-initialize GUI', 13, 10
	db 'fib     - Print the next fibonacci number in hexadecimal', 13, 10
	db 'pong    - Play Pong', 13, 10
	db 'help    - Show this list', 13, 10
	db 'info    - Print info about the CPU', 13, 10
	db 'memv    - View memory', 13, 10
	db 'mouse   - For testing', 13, 10
	db 'panic   - Cause a GPF (General Protection Fault)', 13, 10
	db 'pit     - Print PIT ticks in hexadecimal', 13, 10
	db 'rand    - Print a random 32-bit number in hexadecimal', 13, 10
	db 'restart - Restart the computer', 0
	
; Вывод случайного числа в формате "0xXXXXXXXX"
rand_cmd:
	; "0x"
	mov byte [pos_x], 0
	mov byte [pos_y], 2
	mov al, '0'
	call print_char
	mov al, 'x'
	call print_char
	
	; Число
	call rng_next
	mov [reg32], eax
	call print_reg32
	
	ret
rand_cmd_str db 'rand', 0

; Вывод информации об процессоре на экран
info_cmd:
	; Получить строку продавца
	xor eax, eax
	cpuid

	; Копировать строку из EBX, EDX, ECX
	mov esi, vendor_str
	mov dword [esi], ebx
	add esi, 4

	mov dword [esi], edx
	add esi, 4

	mov dword [esi], ecx
	add esi, 4

	; Печать строки продавца
	mov byte [pos_x], 0
	mov byte [pos_y], 2
	mov esi, vendor_str_msg
	call print_str
	mov esi, vendor_str
	call println_str

	; Получение и печать Stepping ID
	mov esi, stepping_id_msg
	call print_str
	mov eax, 0x01
	cpuid
	push ax
	and al, 0b00001111
	mov [reg8], al
	call println_reg8

	; Получение и печать модели
	mov esi, model_msg
	call print_str
	pop ax
	and al, 0b11110000
	mov [reg8], al
	call println_reg8

	; Получение и печать семьи
	mov esi, family_msg
	call print_str
	and ah, 0b00001111
	mov [reg8], ah
	call println_reg8

	; Получение информации про FPU и печать
	mov eax, 1
	cpuid
	mov esi, fpu_msg
	call print_str
	; Первый бит DL
	and dl, 0b00000001
	test dl, dl
	jnz .fpu_not_present
.fpu_present:
	; Вывести fpu_msg + yes_msg если FPU есть
	mov esi, yes_msg
	call print_str
	jmp .fpu_endif
.fpu_not_present:	
	; Вывести fpu_msg + no_msg если FPU нет
	mov esi, no_msg
	call print_str
.fpu_endif:
	
	ret
info_cmd_str db 'info', 0
vendor_str_msg db 'Vendor: ', 0
vendor_str times 13 db 0
stepping_id_msg db 'Stepping ID: ', 0
model_msg db 'Model: ', 0
family_msg db 'Family: ', 0
fpu_msg db 'FPU present?: ', 0
yes_msg db 'Yes', 0
no_msg db 'No', 0

; Сделать GPF (General protection fault)
panic_cmd:
	; Будет GPF, в защищённом режиме BIOS прерывания не доступны
	int 10h
	
	; Если не получилось сделать GPF вывести failed_gpf_msg на экран
	mov byte [vga_attr], 0x1F
	call clear_screen
	mov esi, failed_gpf_msg
	mov byte [pos_x], 0
	mov byte [pos_y], 0
	call print_str
	
	; Остановить процессор
	jmp done
panic_cmd_str db 'panic', 0
failed_gpf_msg db 'Failed to produce GPF', 0

; Перезапустить компьютер
restart_cmd:
    cli	; Выключить прерывания
.wait_kbc:
    in al, 0x64		; Статусный порт i8042
    test al, 0x02	; Входной буфер занят?
    jnz .wait_kbc	; Ожидание

	; Перезагрузка (0xFE в порт 0x64)
    mov al, 0xFE	
    out 0x64, al
	
	; Если перезагрузка не сработала вывести failed_restart_msg на экран
	mov byte [vga_attr], 0x1F
	call clear_screen
	mov esi, failed_restart_msg
	mov byte [pos_x], 0
	mov byte [pos_y], 0
	call print_str
	
	; Остановить процессор
	jmp done
restart_cmd_str db 'restart', 0
failed_restart_msg db 'Failed to restart', 0