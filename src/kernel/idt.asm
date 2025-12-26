; ------------------------------------------------------------------
; Interrupt Descriptor Table
; ------------------------------------------------------------------

PIC1    equ 0x20 ; PIC1 порт
PIC2    equ 0xA0 ; PIC2 порт
PIC_EOI equ 0x20 ; PIC EOI

; ------------------------------------------------------------------

; Макрос для ISR exception прерываний
%macro isr 2
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

; Инициализация PIC (remap 0x20..0x2F)
init_pic:
	; ICW1: start initialization
	mov al, 0x11
	out 0x20, al
	out 0xA0, al
	
	; ICW2: master vector offset = 0x20, slave = 0x28
	mov al, 0x20
	out 0x21, al
	mov al, 0x28
	out 0xA1, al
	
	; ICW3: wiring
	mov al, 0x04	; master: bitmask, slave on IRQ2
	out 0x21, al
	mov al, 0x02	; slave identity = 2
	out 0xA1, al
	
	; ICW4: 8086 mode
	mov al, 0x01
	out 0x21, al
	out 0xA1, al
	
	; Master PIC, включение IRQ0, IRQ1, IRQ2
	mov al, 11111000b
	out 0x21, al

	; Slave PIC, включение IRQ12
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
	mov al, ah					; Нельзя прямо вывести AH, поэтому перенос AH -> AL
	out 0x40, al				; Верхний байт
	
	; PIT - IRQ0 (индекс 0x20)
	mov ebx, 0x20
	mov eax, system_timer
	call set_idt_entry

	; Клавиатура - IRQ1 (индекс 0x21)
	mov ebx, 0x21
	mov eax, keyboard_stub
	call set_idt_entry

	; Мышка - IRQ12 (индекс 0x2C)
	mov ebx, 0x2C
	mov eax, mouse_stub
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

	mov eax, [esp]
	mov dword [reg32], eax
	call println_reg32

	mov eax, [esp + 4]
	mov dword [reg32], eax
	call println_reg32

	mov eax, [esp + 8]
	mov dword [reg32], eax
	call println_reg32

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