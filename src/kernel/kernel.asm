; ------------------------------------------------------------------
; Ядро
; ------------------------------------------------------------------

org 0x8000

; Загрузчик ядра
%include "src/boot/stage2.asm"

bits 32

; Interrupt Descriptor Table
%include "src/kernel/idt.asm" 

; Стартовая точка ядра
protected_start:
	; TSS
	mov dword [tss32 + 4], stack_top
	mov word  [tss32 + 8], DATA_SEL

	mov eax, tss32
	mov ecx, tss_end - tss32 - 1
	mov edi, gdt_start + 5*8

	mov word [edi+0], cx

	mov word [edi+2], ax
	shr eax, 16
	mov byte [edi+4], al

	mov byte [edi+5], 10001001b

	shr ecx, 16
	mov byte [edi+6], cl

	shr eax, 8
	mov byte [edi+7], al

	mov ax, TSS_SEL
	ltr ax

	; Сегменты
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

	; Мышка
	call mouseinit

	sti ; Включить прерывания

	; Отключить VGA мигание
	call disable_blink
	
	; Включить A20 Line (доступ к >1МБ ОЗУ)
	call enable_A20
	
	; Установить форму курсора
	mov ah, 0b00000000
	call set_cursor

; Сама ОС (GUI, ввод, и т. д.)
%include "src/os/os.asm"

done:
	cli
	hlt
	jmp done

; ------------------------------------------------------------------

; Драйвер VGA
%include "src/drivers/vga.asm"

; Драйвер Real Time Clock
%include "src/drivers/rtc.asm"

; Драйвер PC Speaker
%include "src/drivers/speaker.asm"

; Драйвер мышки
%include "src/drivers/mouse.asm"

; A20 Line
%include "src/kernel/a20.asm"

; ------------------------------------------------------------------

; Функции для печати на экран
%include "src/functions/print.asm"

; Функции для работы со строками
%include "src/functions/str.asm"

; ------------------------------------------------------------------

; Вызвать Ring 3 функцию
;
; Адрес: EAX
call_ring3:
	push eax

	cli
	mov ax, 0x23
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	pop eax

	push 0x23
	push esp
	pushfd
	push 0x1b
	push eax
	iretd
	
; ------------------------------------------------------------------

bits 32

; Данные
%include "src/kernel/data.asm"

; 4 КиБ стек
stack_bottom:
	times 4096 db 0
stack_top: