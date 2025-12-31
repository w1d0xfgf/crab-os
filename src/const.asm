; GDT селекторы
CODE_SEL equ 0x08     ; Код Ring 0
DATA_SEL equ 0x10     ; Данные Ring 0

; PIC
PIC1		equ 0x20  ; Master PIC порт команд
PIC1_DATA	equ 0x21  ; Master PIC порт данных
PIC2		equ 0xA0  ; Slave PIC порт команд
PIC2_DATA	equ 0xA1  ; Slave PIC порт данных
PIC_EOI		equ 0x20  ; PIC EOI

; PIT
PIT_FREQ equ 10000    ; Частота PIT

; Клавиатура
KEY_QUEUE_SIZE equ 16 ; Размер очереди клавиш

; Настройки мыши
MOUSE_RESOLUTION equ 2
MOUSE_SAMPLE_RATE equ 60

; VGA
VIDEO_MEMORY equ 0xB8000