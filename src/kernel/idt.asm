; ------------------------------------------------------------------
; Interrupt Descriptor Table
; ------------------------------------------------------------------

PIC1		equ 0x20 ; Master PIC порт команд
PIC1_DATA	equ 0x21 ; Master PIC порт данных
PIC2		equ 0xA0 ; Slave PIC порт команд
PIC2_DATA	equ 0xA1 ; Slave PIC порт данных
PIC_EOI		equ 0x20 ; PIC EOI

; ------------------------------------------------------------------

; Макрос для ISR exception прерываний
%macro isr 2
	cli

	; Скрыть курсор
	mov ah, 00010000b
	call set_cursor
	
	; Очистить экран цветом vga_attr
	mov byte [vga_attr], %2
	call clear_screen
	
	; Вывести сообщение
	mov byte [pos_x], 0
	mov byte [pos_y], 0
	mov esi, panic_msg
	call println_str
	
	mov esi, %1
	mov byte [pos_x], 2
	mov byte [pos_y], 7
	call println_str

	call flush_buffer
	
	; Остановить процессор
	cli
	hlt
%endmacro

panic_msg:
	db '      PANIC!          ', 13, 10
	db '                      ', 13, 10
	db '      _~^~^~_         ', 13, 10
	db '  \) /  o o  \ (/     ', 13, 10
	db "    '_   ", 0x7F, "   _'       ", 13, 10
	db "    / '-----' \       ", 0

; ------------------------------------------------------------------

idt:
	times 256 dq 0	; Все записи изначально пустые
idt_end:

; Данные для загрузки IDT
idt_descriptor:
	dw idt_end - idt - 1
	dd idt

; ------------------------------------------------------------------

; Установить одну запись IDT
;
; Индекс: EBX
; Смещение: EAX
set_idt_entry:
	pushad			; Сохранить регистры
	
	mov ecx, ebx	; ECX = индекс * 8, поскольку каждая запись в IDT 8 байт
	shl ecx, 3		;
	lea edi, [idt]
	add edi, ecx	; Добавить к адресу IDT смещение ECX

	; dword low: offset_low (16) | (CODE_SEL << 16)
	mov edx, eax
	and edx, 0xFFFF	; Маска: сохранить только первые 16 битов
	mov ebp, CODE_SEL
	shl ebp, 16
	or edx, ebp
	mov [edi], edx

	; dword high: (zero_byte | (type_attr<<8) | (offset_high<<16))
	mov edx, eax
	shr edx, 16		; Сместить EDX на 16 битов
	and edx, 0xFFFF	; offset_high
	shl edx, 16		; offset_high в 16..31
	mov ebp, 0x8E
	shl ebp, 8		; type_attr в 8..15
	or edx, ebp
	mov [edi + 4], edx

	popad			; Восстановить регистры
	
	ret
	
; ------------------------------------------------------------------

; I/O ожидание (для PIC на старых устройствах обязательно)
%macro io_wait 0
	out 0x80, al ; Отправить данные через неиспользуемый порт
%endmacro

; Инициализация PIC
; Ремап: IRQ 0..15 -> индексы 0x20..0x2F в IDT
; 
; Меняет: AL
init_pic:
	; Начать инициализацию
	mov al, 0x11
	out PIC1, al
	io_wait
	mov al, 0x11
	out PIC2, al
	io_wait
	
	; Смещение Master PIC
	mov al, 0x20
	out PIC1_DATA, al
	io_wait
	; Смещение Slave PIC
	mov al, 0x28
	out PIC2_DATA, al
	io_wait
	
	; Сообщить PIC как Slave PIC и Master PIC соединены
	mov al, 0x04
	out PIC1_DATA, al
	io_wait
	mov al, 0x02
	out PIC2_DATA, al
	io_wait
	
	; 8086 mode вместо 8080 mode
	mov al, 0x01
	out PIC1_DATA, al
	io_wait
	mov al, 0x01
	out PIC2_DATA, al
	io_wait
	
	; Маска прерываний Master PIC: включить IRQ 0, 1, 2
	mov al, 11111000b
	out 0x21, al

	; Маска прерываний Slave PIC: включить IRQ 12
	mov al, 11101111b
	out 0xA1, al
	
	ret
	
; ------------------------------------------------------------------

; Инициализация IDT и PIC
init_idt_and_pic:
	pushad	; Сохранить регистры
	
	call init_pic
	
	; Настройка PIT (Programmable Interval Timer)
	mov al, 00110100b
	out 0x43, al
	mov ax, 1193182 / PIT_FREQ	; Делитель = 1193182 / Частота в Гц
	out 0x40, al				; Нижний байт
	mov al, ah					; Нельзя прямо out AH, поэтому перенос AH -> AL
	out 0x40, al				; Верхний байт

	; Заполнить IRQ0-IRQ7 (IRQ master PIC) пустыми ISR
	mov ebx, 0x20
	mov eax, isr_empty_master
.loopm:
	call set_idt_entry
	inc ebx
	cmp ebx, 0x28
	jb .loopm

	; Заполнить IRQ8-IRQ15 (IRQ slave PIC) пустыми ISR
	mov ebx, 0x28
	mov eax, isr_empty_slave
.loops:
	call set_idt_entry
	inc ebx
	cmp ebx, 0x30
	jb .loops

	; Записать ISR PIT для IRQ0 (индекс 0x20)
	mov eax, pit_stub
	mov ebx, 0x20
	call set_idt_entry

	; Записать ISR клавиатуры для IRQ1 (индекс 0x21)
	mov eax, keyboard_stub
	mov ebx, 0x21
	call set_idt_entry

	; Записать ISR мышки для IRQ12 (индекс 0x2C)
	mov eax, mouse_stub
	mov ebx, 0x2C
	call set_idt_entry
	
	; Исключение ошибки деления (индекс 0x00)
	mov ebx, 0x00
	mov eax, div_err
	call set_idt_entry
	
	; Non-maskable Interrupt (индекс 0x02)
	mov ebx, 0x02
	mov eax, nmi
	call set_idt_entry
	
	; General Protection Fault (индекс 0x0D)
	mov ebx, 0x0D
	mov eax, gpf
	call set_idt_entry
	
	; Page Fault (индекс 0x0E)
	mov ebx, 0x0E
	mov eax, page_fault
	call set_idt_entry

	; Загрузка IDT
	lea eax, [idt_descriptor]
	lidt [eax]
	
	popad	; Восстановить регистры
	
	ret
	
; ------------------------------------------------------------------

; ISR ошибки деления
div_err: isr div_err_msg, 0x1F
div_err_msg: db 'Division error', 0

; ISR Non-Maskable Interrupt
nmi: isr nmi_msg, 0x4F
nmi_msg: db 'Non-maskable Interrupt', 0

; ISR General Protection Fault
gpf:
	cli

	; Скрыть курсор
	mov ah, 00010000b
	call set_cursor

	; Очистить экран цветом vga_attr
	mov byte [vga_attr], 0x1F
	call clear_screen
	
	; Вывести сообщение
	mov byte [pos_x], 0
	mov byte [pos_y], 0
	mov esi, panic_msg
	call println_str
	
	mov esi, gpf_msg
	mov byte [pos_x], 2
	mov byte [pos_y], 7
	call println_str
	inc byte [pos_y]
	
	; Вывести код ошибки, EIP, и CS
	; Стек при GPF:
	; +-----------------------+ ESP + 8
	; | CS (4 байта)          |
	; +-----------------------+ ESP + 4
	; | EIP (4 байта)         |
	; +-----------------------+ ESP
	; | Код ошибки (4 байта)  |
	; +-----------------------+ ESP - 4
	; | - - - - - - - - - - - |
	
	pop eax
	mov dword [reg32], eax
	call println_reg32_hex

	pop eax
	mov dword [reg32], eax
	call println_reg32_hex

	pop eax
	mov dword [reg32], eax
	call println_reg32_hex

	call flush_buffer

	; Остановить процессор
	cli
	hlt
gpf_msg: db 'General Protection Fault', 0

; ISR Page Fault
page_fault: isr page_fault_msg, 0x1F
page_fault_msg: db 'Page Fault', 0

; ------------------------------------------------------------------

; ISR PIT
%include "src/drivers/pit.asm"

; ------------------------------------------------------------------

; ISR клавиатуры
%include "src/drivers/keyboard.asm"

; ------------------------------------------------------------------

; ISR мыши
%include "src/drivers/mouse.asm"

; ------------------------------------------------------------------

; ISR-пустышка для Master PIC
isr_empty_master:
	; Отправить EOI Master PIC
	push eax
	mov al, PIC_EOI
	out PIC1, al
	pop eax

	iretd
	
; ISR-пустышка для Slave PIC
isr_empty_slave:
	; Отправить EOI Slave PIC и Master PIC
	push eax
	mov al, PIC_EOI
	out PIC2, al
	out PIC1, al
	pop eax

	iretd