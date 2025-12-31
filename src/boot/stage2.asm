; ------------------------------------------------------------------
; Stage 2 загрузчика ядра
; ------------------------------------------------------------------

; Компиляция для 16 бит
bits 16

; Смещение 0x8000 к адресам
org 0x8000

; Константы
CODE_SEL equ 0x08 ; GDT селектор кода Ring 0
DATA_SEL equ 0x10 ; GDT селектор данных Ring 0
SMAP equ 0x534D4150 ; 'SMAP'

start:
	; Посчитать количество доступной ОЗУ

	; Для первого вызова функции EBX должен быть 0
	xor ebx, ebx
.next:
	; Получить запись из карты памяти
	mov eax, 0xE820				; Карта памяти
	mov edx, SMAP				; Обязательно
	mov ecx, 24					; 24 байта
	mov di, memory_map_buffer	; Адрес буфера
	int 0x15

	; Если ошибка, завершить
	jc .done

	; Если EAX не 'SMAP', завершить
	cmp eax, SMAP
	jne .done

	; Если тип не 1 (свободная память), пропустить
	cmp dword [memory_map_buffer + 16], 1
	jne .skip

	; Добавить к итоговому количеству ОЗУ 
	mov eax, [memory_map_buffer + 8]
	shr eax, 10
	add [total_ram], eax
	adc dword [total_ram + 4], 0
	mov eax, [memory_map_buffer + 12]
	shl eax, 22
	add [total_ram + 4], eax
.skip:
	test ebx, ebx
	jnz .next
.done:
	; Сохранить total_ram
	mov eax, [total_ram]
	mov dword [0x500], eax
	mov eax, [total_ram + 4]
	mov dword [0x504], eax

	; Отключить прерывания
	cli

	; Загрузить GDT
	lgdt [gdt_descriptor] 

	; Включить A20 Line
	call enable_A20

	; Перейти в защищённый режим
	mov eax, cr0			
	or eax, 1
	mov cr0, eax

	; Far-прыжок в ядро для обновления Code Segment
	jmp CODE_SEL:pm_entry

; ------------------------------------------------------------------

; A20 Line
%include "src/boot/a20.asm"

; ------------------------------------------------------------------

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

; Дескриптор GDT
gdt_descriptor:
	dw gdt_end - gdt_start - 1 	; Лимит
	dd gdt_start 				; Адрес (32 бит)

; ------------------------------------------------------------------

; Буфер одной записи в карте памяти
memory_map_buffer:
	dq 0
	dq 0
	dd 0
	dd 0

; Счётчик ОЗУ в КБ
total_ram dq 0

; ------------------------------------------------------------------

; Заполнить до 512 байт, ядро точно будет по адресу 0x8200
times 512 - ($ - $$) db 0 

; Ядро в памяти сразу после Stage 2
pm_entry: