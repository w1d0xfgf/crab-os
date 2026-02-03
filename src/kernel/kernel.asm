; ------------------------------------------------------------------
; Ядро
; ------------------------------------------------------------------

; Компиляция для 32 бит
bits 32

%include "src/const.asm"

extern stack_bottom
extern stack_top

extern set_cursor
extern mouse_init
extern disable_blink
extern init_idt_and_pic
extern os_entry
extern fdc_init
extern fdd_read
extern fdd_write
extern fdd_motor_on
extern fdd_motor_off

extern print_reg32
extern println_reg32
extern print_reg32_hex
extern println_reg32_hex
extern print_str
extern print_char
extern println_str
extern clear_screen
extern flush_buffer

extern wait_key

extern mem_free
extern mem_map_set_region
extern mem_alloc

extern vga_attr
extern reg32
extern pos_x
extern pos_y
extern key_queue_top

global kernel_entry
global scancode_to_ascii
global scancode_to_ascii_shift
global halt
global total_ram

; Количество записей в карте памяти
MAX_MEM_MAP_ENTRIES equ 128

; Код
section .text

; Перепрыгнуть через данные
jmp kernel_entry

; Адрес карты памяти для передачи из Stage 2
dw memory_map

; Стартовая точка ядра
kernel_entry:
	cli

	; Сегменты
	mov ax, DATA_SEL
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	
	; Стек
	mov ss, ax
	mov esp, stack_top
	mov ebp, esp

	; IDT
	call init_idt_and_pic

	; Очистить экран
	mov byte [vga_attr], 0x07
	call clear_screen
	call flush_buffer

	; Лог
	mov esi, log_1
	call log_info

	; Инициализировать мышку
	call mouse_init

	; CF = 1 после инициализации значит ошибка
	jc .mouse_error
.mouse_ok:
	; Лог успеха
	mov esi, log_2
	call log_ok
	jmp .mouse_done
.mouse_error:
	; Лог ошибки
	mov esi, log_2
	call log_error
.mouse_done:

	sti

	; Инициализировать FDC
	call fdc_init

	; CF = 1 после инициализации значит ошибка
	jc .fdc_error
.fdc_ok:
	; Лог успеха
	mov esi, log_3
	call log_ok
	jmp .fdc_done
.fdc_error:
	; Лог ошибки
	mov esi, log_3
	call log_error
.fdc_done:

	; Заполнить Bitmap единицами
	mov ebx, 0
	mov ecx, 0xFFFFFFFF
	call mem_map_set_region

	; Посчитать количество доступной ОЗУ
	mov ecx, 0
	mov esi, memory_map
.next:
	; Если тип не 1 (свободная память), пропустить
	cmp dword [esi + 16], 1
	jne .skip

	; Добавить к итоговому количеству ОЗУ 
	mov eax, [esi + 8]
	shr eax, 10
	add [total_ram], eax
	adc dword [total_ram + 4], 0
	mov eax, [esi + 12]
	shl eax, 22
	add [total_ram + 4], eax

	push ecx

	; Инцициализировать память в PMM

	; Выходит ли база за 32 бита?
	cmp dword [esi + 4], 0
	jne .skip

	; Базовый адрес
	mov ebx, [esi]
	shr ebx, 12

	; Выходит ли длина за 32 бита?
	cmp dword [esi + 12], 0
	jne .too_long

	; Длина
	mov ecx, [esi + 8]
	add ecx, 4095
	shr ecx, 12
	
	call mem_free
	jmp .type1_skip
.too_long:
	; Поскольку длина слишком большая, заменим её на самое большое возможное число 
	mov ecx, 0xFFFFFFFF

	call mem_free
.type1_skip:
	pop ecx
.skip:
	add esi, 24
	inc ecx
	cmp ecx, MAX_MEM_MAP_ENTRIES
	jb .next
.done:

	; Выделить DMA 0x2500 в PMM
	mov ebx, 0x1000 >> 12
	mov ecx, (0x2500 + 4095) >> 12
	call mem_map_set_region

	; Выделить ядру 16 страниц в PMM
	mov ebx, 0x8200 >> 12
	mov ecx, 16
	call mem_map_set_region

	; Выделить VGA буферу 1 страницу в PMM
	mov ebx, 0xB8000 >> 12
	mov ecx, 1
	call mem_map_set_region

	; Лог
	mov esi, log_4
	call log_info

	; Вывести карту памяти
	call list_memory_map
	
	; Отключить VGA мигание
	call disable_blink

	; Установить форму курсора
	mov ah, 00010000b
	call set_cursor

	; Лог
	mov esi, log_5
	call log_info

	; Подождать нажатие клавиши
	mov byte [key_queue_top], 0
	call wait_key
	mov byte [key_queue_top], 0

	; Установить форму курсора
	mov ah, 00000000b
	call set_cursor

	; Перейти в ОС
	jmp os_entry
	
halt:
	hlt
	jmp halt

; ------------------------------------------------------------------

; Вывести лог успеха
log_ok:
	push esi
	mov byte [vga_attr], 0x02
	mov esi, log_ok_str
	call print_str
	inc byte [pos_x]
	pop esi
	mov byte [vga_attr], 0x07
	call println_str
	call flush_buffer
	
	ret

; Вывести лог ошибки
log_error:
	push esi
	mov byte [vga_attr], 0x04
	mov esi, log_error_str
	call print_str
	inc byte [pos_x]
	pop esi
	mov byte [vga_attr], 0x07
	call println_str
	call flush_buffer

	ret

; Вывести лог информации
log_info:
	push esi
	mov byte [vga_attr], 0x03
	mov esi, log_info_str
	call print_str
	inc byte [pos_x]
	pop esi
	mov byte [vga_attr], 0x07
	call println_str
	call flush_buffer

	ret

; ------------------------------------------------------------------

; Вывести карту памяти
list_memory_map:
	mov ecx, 0
	mov esi, memory_map
.next:
	; Цвет фона (серый/чёрный) на основе чётности номера
	test ecx, 1
	jnz .odd
.even:
	mov byte [vga_attr], 0x07
	jmp .endif
.odd:
	mov byte [vga_attr], 0x87
.endif:

	push ecx

	; Тип 0 = неопределённая запись (конец)
	cmp byte [esi + 16], 0
	je .done

	; Вывести Base
	push esi
	mov esi, base_msg
	call print_str
	pop esi
	mov eax, [esi]
	mov [reg32], eax
	push esi
	call print_reg32_hex
	pop esi
	mov eax, [esi + 4]
	mov [reg32], eax
	push esi
	call print_reg32_hex
	pop esi
	mov al, ' '
	call print_char

	; Вывести Length
	push esi
	mov esi, length_msg
	call print_str
	pop esi
	mov eax, [esi + 8]
	mov [reg32], eax
	push esi
	call print_reg32_hex
	pop esi
	mov eax, [esi + 12]
	mov [reg32], eax
	push esi
	call print_reg32_hex
	pop esi
	mov al, ' '
	call print_char

	; Вывести тип
	push esi
	mov esi, type_msg
	call print_str
	pop esi
	mov eax, [esi + 16]
	mov [reg32], eax
	push esi
	call println_reg32
	pop esi

	pop ecx
	add esi, 24
	inc ecx
	cmp ecx, 19
	jb .next

.done:
	pop ecx
	ret

; ------------------------------------------------------------------

; Данные
section .data

%include "src/kernel/data.asm"

; Сообщения логов
log_error_str db '[  X  ]', 0
log_ok_str db '[  ', 0xFB, '  ]', 0
log_info_str db '[ (i) ]', 0
log_1 db 'Initialized IDT', 0
log_2 db 'Initialized PS/2 mouse', 0
log_3 db 'Initialized FDC', 0
log_4 db 'Processed memory map:', 0
log_5:
	db 'VGA is set up', 13, 10
	db 'Press any key to continue...', 0

base_msg db 'Base: ', 0
length_msg db 'Length: ', 0
type_msg db 'Type: ', 0

; Неинициализированные данные
section .bss

; Карта памяти
memory_map: resb 24*MAX_MEM_MAP_ENTRIES

; Количество ОЗУ в КБ
total_ram: resq 1