; ------------------------------------------------------------------
; Загрузчик ядра
; ------------------------------------------------------------------

bits 16

; GDT селекторы
%define CODE_SEL 0x08
%define DATA_SEL 0x10

start:
	; Загрузка кастомной программы

    cli ; Отключить прерывания				
    lgdt [gdt_descriptor] ; Загрузка GDT

	; Переход в защищённый режим
	mov eax, cr0			
	or eax, 1
    mov cr0, eax

	; Far-прыжок в ядро
    jmp CODE_SEL:protected_start

; GDT
gdt_start:
    ; NULL дескриптор (обязательно)
    dd 0x00000000
    dd 0x00000000

    ; Дескриптор сегмента кода
	; Адрес 0, лимит 0xFFFFF, access 0x9A, флаги 0xCF (G=1, D/B=1)
    dw 0xFFFF 		; Лимит (нижние биты)
    dw 0x0000 		; Адрес (нижние биты)
    db 0x00 		; Адрес (средние биты)
    db 0b10011010 	; Access
    db 0xCF 		; Granularity + Лимит (верхние биты)
    db 0x00 		; Адрес (верхние биты)

    ; Дескриптор сегмента данных
	; Адрес 0, лимит 0xFFFFF, access 0x92, флаги 0xCF
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0b10010010
    db 0xCF
    db 0x00
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1 	; Лимит
    dd gdt_start 				; Адрес (32 бит)