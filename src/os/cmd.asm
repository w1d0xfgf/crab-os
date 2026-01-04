; ------------------------------------------------------------------
; Команды в консоли
; ------------------------------------------------------------------

bits 32

global version_cmd
global mouse_cmd
global beep_cmd
global memv_cmd
global cls_cmd
global pit_cmd
global pong_cmd
global fib_cmd
global help_cmd
global rand_cmd
global info_cmd
global panic_cmd
global restart_cmd

extern init_gui
extern print_reg32
extern println_reg32
extern print_reg32_hex
extern print_char
extern print_str
extern println_str
extern play_sound
extern stop_sound
extern sleep_ticks
extern rng_next
extern halt
extern set_cursor
extern clear_screen
extern keys_pressed
extern flush_buffer
extern wait_key
extern ps2_wait_wr
extern kernel_entry

extern vga_attr
extern pos_x
extern pos_y
extern reg8
extern reg32
extern pit_ticks
extern mouse_x
extern mouse_y
extern mouse_state
extern total_ram
extern key_queue
extern key_queue_top

; ------------------------------------------------------------------

; Код
section .text

; Версия ОС
version_cmd:
	mov esi, version_str
	call print_str

	ret

; ------------------------------------------------------------------

; Тест мышки
mouse_cmd:
	%include "src/os/cmd/mouse.asm"

; ------------------------------------------------------------------

; Бип
beep_cmd:
	; Включить звук с частотой 1500 Гц
	mov ecx, 1500
	call play_sound

	; Подождать 1000 тиков
	mov edx, 1000
	call sleep_ticks

	; Выключить звук
	call stop_sound
	
	ret

; ------------------------------------------------------------------

; Просмотреть память
memv_cmd:
	%include "src/os/cmd/memv.asm"

; ------------------------------------------------------------------

; Очистить экран
cls_cmd:
	call init_gui

	ret

; ------------------------------------------------------------------

; Вывести тики PIT на экран
pit_cmd:
	mov eax, [pit_ticks]
	mov [reg32], eax
	call print_reg32

	ret

; ------------------------------------------------------------------

; Игра Pong
pong_cmd:
	%include "src/os/cmd/pong.asm"

; ------------------------------------------------------------------

; Вывод следующего числа фибоначчи
fib_cmd:
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

; ------------------------------------------------------------------

; Вывод списка команд
help_cmd:
	mov esi, cmd_list_msg
	call print_str
	
	ret

; ------------------------------------------------------------------
	
; Вывод случайного числа
rand_cmd:
	call rng_next
	mov [reg32], eax
	call print_reg32
	
	ret

; ------------------------------------------------------------------

; Вывод информации об системе на экран
info_cmd:
	%include "src/os/cmd/info.asm"

; ------------------------------------------------------------------

; Сделать GPF (General protection fault)
panic_cmd:
	; Загрузить некорректный сегмент (селектор 0x30 не существует)
	mov ax, 0x30
	mov ds, ax
	
	ret

; ------------------------------------------------------------------

; Перезапустить компьютер
restart_cmd:
	call ps2_wait_wr

	; Перезагрузка (0xFE в порт 0x64)
	mov al, 0xFE	
	out 0x64, al
	
	; Остановить процессор
	jmp halt

; ------------------------------------------------------------------

; Данные
section .data

version_str db 'v0.1.6', 0

escape_msg db 'Press <Escape> to exit', 0

memv_location dd 0
memv_help db 'W/S: Up/Down  U/D: Fast Up/Down', 0
adress_msg db 'Adress: ', 0

fib_f1 dd 1
fib_f0 dd 1

cmd_list_msg:
	db 'Commands:', 13, 10
	db 'beep    - Make a beep', 13, 10
	db 'cls     - Clear the screen and re-initialize GUI', 13, 10
	db 'fib     - Print the next fibonacci number', 13, 10
	db 'pong    - Play Pong', 13, 10
	db 'help    - Show this list', 13, 10
	db 'info    - Print info about the system', 13, 10
	db 'memv    - View memory', 13, 10
	db 'mouse   - For testing', 13, 10
	db 'panic   - Cause a GPF (General Protection Fault)', 13, 10
	db 'pit     - Print PIT ticks', 13, 10
	db 'rand    - Print a random 32-bit number', 13, 10
	db 'restart - Restart the computer', 13, 10
	db 'version - Show OS version', 0