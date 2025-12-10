; ------------------------------------------------------------------
; Interrupt descriptor table
; ------------------------------------------------------------------
; Interrupt descriptor table (IDT) - таблица прерываний, которая
; описывает где находятся ISR'ы которые процессор должен вызывать
; при соответствующих им прерываниям
; ------------------------------------------------------------------

%define PIC1 0x20
%define PIC2 0xA0
%define PIC_EOI 0x20

; Макрос для ISR которые выводят сообщение и останавливают процессор
%macro isr 2
	; Скрыть курсор
	mov ah, 0b00010000
	call set_cursor

	; Очистить экран цветом attr
	mov byte [attr], %2
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
	
	; Без прерываний инструкция hlt (halt)
	; не возобновит работу процессора
	cli	; Отключить прерывания
	hlt	; Halt
%endmacro

idt:
    times 256 dq 0	; Все записи изначально пустые
idt_end:

; Данные для загрузки IDT
idt_descriptor:
    dw idt_end - idt - 1
    dd idt

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
    and edx, 0xFFFF ; offset_high
    shl edx, 16     ; offset_high в 16..31
    mov ebp, 0x8E
    shl ebp, 8      ; type_attr в 8..15
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
    mov al, 0x04     ; master: bitmask, slave on IRQ2
    out 0x21, al
    mov al, 0x02     ; slave identity = 2
    out 0xA1, al
	
    ; ICW4: 8086 mode
    mov al, 0x01
    out 0x21, al
    out 0xA1, al
	
    ; Маска — разблокировать клавиатуру (IRQ1) — установка 0
    ; Разблокировать IRQ1 и IRQ0
    mov al, 0b11111100
    out 0x21, al
    mov al, 0xFF
    out 0xA1, al
	
    ret
	
; ------------------------------------------------------------------

; Инициализация IDT и PIC
init_idt_and_pic:
    pushad	; Сохранить регистры
	
    call init_pic
	
	; Настройка PIT (Programmable Interval Timer)
	mov al, 0b00110100
    out 0x43, al

    mov ax, 11931	; Делитель = 1193182 / Частота в Гц
    out 0x40, al	; Нижний байт
    mov al, ah		; Нельзя прямо вывести AH, поэтому перенос AH -> AL
    out 0x40, al	; Верхний байт
	
	; PIT - IRQ0 (индекс 0x20)
    mov ebx, 0x20
    mov eax, system_timer
    call set_idt_entry

    ; Клавиатура - IRQ1 (индекс 0x21)
    mov ebx, 0x21
    mov eax, keyboard_stub
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

div_err: isr div_err_msg, 0x1F
div_err_msg: db "Division error", 0

nmi: isr nmi_msg, 0x4F
nmi_msg: db "Non-maskable Interrupt", 0

gpf: isr gpf_msg, 0x1F
gpf_msg: db "General Protection Fault", 0

page_fault: isr page_fault_msg, 0x1F
page_fault_msg: db "Page Fault", 0

; ------------------------------------------------------------------

; ISR PIT прерывания
system_timer:
	push eax
	
    inc word [system_timer_ticks]
    mov al, PIC_EOI
    out PIC1, al
	
    pop eax
	
    iret
	
system_timer_ticks dw 0	; Количество тиков PIT

; ------------------------------------------------------------------

; Keyboard ISR stub, handler
; Стуб сохраняет регистры, вызывает обработчик, посылает EOI и iret
keyboard_stub:
    pusha
    push ds
    push es
    mov ax, DATA_SEL
    mov ds, ax
    mov es, ax

    call keyboard_handler

    pop es
    pop ds
    popa
	
    ; EOI для master PIC
    mov al, PIC_EOI
    out PIC_EOI, al
    iret

%include "src/drivers/keyboard.asm"