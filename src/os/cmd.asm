; ------------------------------------------------------------------
; Команды в консоли
; ------------------------------------------------------------------

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
	db 'fib     - Print the next fibonacci number'
	db 'help    - Show this list', 13, 10
	db 'rand    - Print a random 32-bit value', 13, 10
	db 'panic   - Cause a GPF (General Protection Fault)', 13, 10
	db 'restart - Power cycle the motherboard', 13, 10
	db 'ping    - Print "pong"', 0
	
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

; Вывод "pong" на экран
ping_cmd:
	mov esi, pong_msg
	mov byte [pos_x], 0
	mov byte [pos_y], 2
	call print_str
	
	ret
ping_cmd_str db 'ping', 0
pong_msg db 'pong', 0

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