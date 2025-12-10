; ------------------------------------------------------------------
; Ядро
; ------------------------------------------------------------------

; TODO: Сделать IDT клавиатурную очередь FIFO а не LIFO
; TODO: Перенести все функции связанные со строками в src/functions/str.asm

org 0x8000

; Загрузчик ядра
%include "src/boot/stage2.asm"

bits 32

; Interrupt Descriptor Table
%include "src/kernel/idt.asm"

; Стартовая точка ядра
protected_start:
    mov ax, DATA_SEL
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
	
	; Стек
    mov ss, ax
    mov esp, stack_top
	
	; IDT
	call init_idt_and_pic
	
    sti ; Включение прерываний
	
	; Инициализация GUI
	call init_gui
	
	; Установить форму курсора
	mov ah, 0b00000000
	call set_cursor

; Цикл программы
event_loop:
	; Тест PIT ISR
	mov al, [pos_x]
	mov ah, [pos_y]
	push ax
	
	mov byte [pos_x], 12
	mov byte [pos_y], 5
	mov eax, [system_timer_ticks]
	mov [reg32], eax
	call print_reg32
	
	pop ax
	mov [pos_y], ah
	mov [pos_x], al

	; Обновление GUI
	mov byte [attr], 0x70
	call update_gui
	mov byte [attr], 0x07
		
	; Обработка нажатия клавиши
.handle_key:
	; Очередь клавиш
	movzx ebx, byte [key_queue_top]		; Проверить есть ли в очереди клавиши
	cmp ebx, 0							; 
	je .skip_key						; Пропустить обработку клавиши если очередь пустая
	
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
	call input_done
.finished_key:
	; Убрать элемент после того как он был обработан
	dec byte [key_queue_top]
	jmp .skip_key
.backspace:
	call reset_user_input
	call init_gui
	jmp .finished_key
.skip_key:
    jmp event_loop	

; Макрос для команд
%macro command 1
	; Сравнить строки
	mov esi, user_input
	mov edi, %1
	call compare_strs
	cmp edx, 1
%endmacro

input_done:
	; Сбросить GUI
	call init_gui

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
	jne .end
	call ping_cmd
.end:
	; Сбросить ввод
	call reset_user_input
	mov byte [pos_x], 2
	mov byte [pos_y], 4
	
	ret

done:
	cli
	hlt
	jmp done

; ------------------------------------------------------------------

; Драйвер VGA
%include "src/drivers/vga.asm"

; Драйвер Real Time Clock
%include "src/drivers/rtc.asm"

; ------------------------------------------------------------------

; Функции для печати на экран
%include "src/functions/print.asm"

; GUI
%include "src/kernel/gui.asm"

; ------------------------------------------------------------------

; Функции для работы со строками
%include "src/functions/str.asm"

; PRNG (xoshiro128**)
%include "src/functions/rng.asm"

; ------------------------------------------------------------------

ping_cmd:
	; "pong"
	mov esi, pong_msg
	mov byte [pos_x], 0
	mov byte [pos_y], 6
	call print_str
	
	ret
ping_cmd_str db 'ping', 0
pong_msg db 'pong', 0

panic_cmd:
	; Будет GPF, в защищённом режиме BIOS прерывания не доступны
	int 10h
	
	; Если не получилось сделать GPF вывести сообщение на экран
	mov byte [attr], 0x4F
	mov esi, failed_gpf_msg
	mov byte [pos_x], 0
	mov byte [pos_y], 0
	call print_str
	
	; Остановить процессор
	jmp done
panic_cmd_str db 'panic', 0
failed_gpf_msg db 'Failed to produce GPF', 0

restart_cmd:
    cli	; Выключить прерывания
.wait_kbc:
    in al, 0x64		; Статусный порт i8042
    test al, 0x02	; Входной буфер занят?
    jnz .wait_kbc	; Ожидание

    mov al, 0xFE	; Перезагрузка (0xFE в порт 0x64)
    out 0x64, al
	
	; Если перезагрузка не сработала вывести сообщение на экран
	mov byte [attr], 0x4F
	mov esi, failed_restart_msg
	mov byte [pos_x], 0
	mov byte [pos_y], 0
	call print_str
	
	; Остановить процессор
	jmp done
restart_cmd_str db 'restart', 0
failed_restart_msg db 'Failed to restart', 0

reset_user_input:
	mov ecx, 0
	
	mov byte [user_input_top], 0
	
.loop:
	mov byte [user_input + ecx], 0

	inc ecx
	cmp ecx, 63
	jb .loop
	
	ret
	
; ------------------------------------------------------------------

bits 32
VIDEO_MEM equ 0xB8000 ; Адрес VGA текстового буфера

; Данные
%include "src/kernel/data.asm"

; 4 КиБ стек
stack_bottom:
	times 4096 db 0
stack_top: