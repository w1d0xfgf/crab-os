; ------------------------------------------------------------------
; Stage 2 загрузчика ядра
; ------------------------------------------------------------------

bits 16

; GDT селекторы
CODE_SEL      equ 0x08	; Код Ring 0
DATA_SEL      equ 0x10	; Данные Ring 0
USER_CODE_SEL equ 0x18	; Код Ring 3
USER_DATA_SEL equ 0x20	; Данные Ring 3

start:
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
	dd 0
	dd 0
	
	; Дескриптор сегмента кода
	; Базовый адрес 0, лимит 0xFFFFF, access 0x9A, флаги 0x0C (G=1, D/B=1)
	dw 0xFFFF 		; Лимит (нижние биты)
	dw 0x0000 		; Базовый адрес (нижние биты)
	db 0x00 		; Базовый адрес (средние биты)
	db 10011010b 	; Access
	db 0xCF 		; Флаги + Лимит (верхние биты)
	db 0x00 		; Адрес (верхние биты)

	; Дескриптор сегмента данных
	; Базовый адрес 0, лимит 0xFFFFF, access 0x92, флаги 0x0C
	dw 0xFFFF
	dw 0x0000
	db 0x00
	db 10010010b
	db 0xCF
	db 0x00
gdt_end:

gdt_descriptor:
	dw gdt_end - gdt_start - 1 	; Лимит
	dd gdt_start 				; Адрес (32 бит)