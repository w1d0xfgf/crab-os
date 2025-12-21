; ------------------------------------------------------------------
; Загрузчик ядра
; ------------------------------------------------------------------

bits 16

; GDT селекторы
CODE_SEL equ 0x08		; Код Ring 0
DATA_SEL equ 0x10		; Данные Ring 0
USER_CODE_SEL equ 0x18	; Код Ring 3
USER_DATA_SEL equ 0x20	; Данные Ring 3
TSS_SEL equ 0x28		; TSS

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

	; Дескриптор сегмента кода User mode
	; Адрес 0, лимит 0xFFFFF, access 0xFA, флаги 0x0C (G=1, D/B=1)
	dw 0xFFFF 		; Лимит (нижние биты)
	dw 0x0000 		; Адрес (нижние биты)
	db 0x00 		; Адрес (средние биты)
	db 0xFA 		; Access
	db 0x0C 		; Granularity + Лимит (верхние биты)
	db 0x00 		; Адрес (верхние биты)

	; Дескриптор сегмента данных User mode
	; Адрес 0, лимит 0xFFFFF, access 0xF2, флаги 0x0C
	dw 0xFFFF
	dw 0x0000
	db 0x00
	db 0xF2
	db 0x0C
	db 0x00

	; TSS (пустое)
	dq 0
gdt_end:

gdt_descriptor:
	dw gdt_end - gdt_start - 1 	; Лимит
	dd gdt_start 				; Адрес (32 бит)

; TSS
align 4
tss32:
	times 104 db 0
tss_end: