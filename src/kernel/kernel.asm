; ------------------------------------------------------------------
; Ядро
; ------------------------------------------------------------------

; TODO: Добавить больше команд
; TODO: Сделать IDT клавиатурную очередь FIFO а не LIFO
; TODO: Сделать выделение памяти

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
	
    sti ; Включить прерывания
	
	; Включить A20 Line (>1МБ ОЗУ)
	call enable_A20
	
	; PRNG
	call get_rtc_time
	; Первые 2 байта State[0] = 0xMMSS (M - минуты, S - секунды)
	mov word [rng_state], bx	
	; Вторые 2 байта State[0] = 0xDDHH (D - дни, H - часы)
	mov word [rng_state + 2], cx
	
	; Инициализизовать GUI
	call init_gui
	
	; Установить форму курсора
	mov ah, 0b00000000
	call set_cursor
	
; ------------------------------------------------------------------

; Цикл программы
event_loop:
	; Обновление GUI
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
	jne .finished_key
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
	
; ------------------------------------------------------------------

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
	
	; Если ввод пустой, пропустить обработку команд
	cmp byte [user_input], 0
	je .ret
	
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
	jne .fail
	call rand_cmd
	jmp .end
.fail:
	; Вывести invalid_cmd_msg на экран
	mov byte [attr], 0x04		; Красный
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
invalid_cmd_msg db 'Invalid command', 0

; ------------------------------------------------------------------

done:
	cli
	hlt
	jmp done

; ------------------------------------------------------------------

; Драйвер VGA
%include "src/drivers/vga.asm"

; Драйвер Real Time Clock
%include "src/drivers/rtc.asm"

; Код для включения A20 Line
%include "src/kernel/a20.asm"

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

; Команды
%include "src/kernel/cmd.asm"

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

bits 32
VIDEO_MEM equ 0xB8000 ; Адрес VGA текстового буфера

; Данные
%include "src/kernel/data.asm"

; 4 КиБ стек
stack_bottom:
	times 4096 db 0
stack_top: