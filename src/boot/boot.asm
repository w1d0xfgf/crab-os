; ------------------------------------------------------------------
; Загрузчик 2 стадии
; ------------------------------------------------------------------

; Загружается в 0x0000:0x7C00
org 0x7C00

start:
    cli ; Отключим прерывания на время настройки
    xor ax, ax ; AX = 0
    mov ds, ax ; DS = 0
    mov es, ax ; ES = 0
    mov ss, ax ; SS = 0
    mov sp, 0x7C00 ; Стек
    sti

    mov [boot_drive], dl ; Сохранить номер загрузочного диска (DL от BIOS)

    ; Загрузить Stage 2 с ядром в 0x0000:0x8000
    mov bx, 0x8000 			; Смещение
	xor ax, ax 				; AX = 0
	mov es, ax 				; ES = 0
    mov ah, 0x02 			; BIOS Прерывание 0x13 AH = 0x02 - Чтение секторов в память
    mov al, 32 				; Число секторов
    mov ch, 0 				; Cylinder = 0
    mov cl, 2 				; Читать начиная с сектора #2 (#1 - сектор в котором бутлоадер)
    mov dh, 0				; Head = 0
    mov dl, [boot_drive] 	; Номер загрузочного диска
    int 0x13
    jc disk_error 			; CF = 1 -> Ошибка
	
    ; Переход на загруженный код: сегмент 0x0000, смещение 0x8000
    jmp 0x0000:0x8000

; Если ошибка чтения, напечатать сообщение и остановиться
disk_error:
	; Адрес disk_err_msg -> SI
    mov si, disk_err_msg
.print_loop:
	; Загрузка символа (по адресу SI)
    lodsb 
	
	; Если символ NULL (код 0), значит конец строки
    or al, al
    jz .halt
	
	; BIOS Прерывание 0x10 AH = 0x0E - Teletype
    mov ah, 0x0E
    mov bh, 0x00 	; Страница 0
    mov bl, 0x07 	; Цвет
    int 0x10
    jmp .print_loop
.halt:
    cli
    hlt
    jmp .halt

; Данные
boot_drive db 0
disk_err_msg db 'Disk read error', 0

times 510 - ($ - $$) db 0 ; Заполнить до 510 байт
dw 0xAA55 ; Ещё 2 байта - сигнатура 0x55AA (обязательно)