; ------------------------------------------------------------------
; Stage 1 загрузчика ядра
; ------------------------------------------------------------------

; Компиляция для 16 бит
bits 16

; Смещение 0x7C00 к адресам
org 0x7C00

; Стартовая точка
start:
	cli 			; Отключить прерывания
	xor ax, ax		; AX = 0
	mov ds, ax		; DS = 0
	mov es, ax		; ES = 0
	mov ss, ax		; SS = 0
	mov sp, 0x7C00	; Стек
	sti				; Включить прерывания

	; Сохранить номер загрузочного диска (DL от BIOS)
	mov [boot_drive], dl
	
	; Загрузить Stage 2 с ядром в 0x0000:0x8000
	mov bx, 0x8000			; Смещение
	xor ax, ax				; AX = 0
	mov es, ax				; ES = 0
	mov ah, 0x02			; AH = 0x02 -- BIOS чтение секторов в память
	mov al, 64				; Число секторов
	mov ch, 0				; Cylinder = 0
	mov cl, 2				; Читать начиная с сектора #2 (#1 -- сектор в котором бутлоадер)
	mov dh, 0				; Head = 0
	mov dl, [boot_drive]	; Номер загрузочного диска
	int 0x13				; Вызов BIOS через прерывание 0x13
	jc disk_error			; BIOS поставит CF = 1 если ошибка
	
	; Переход на загруженный код: сегмент 0x0000, смещение 0x8000
	jmp 0x0000:0x8000

; Если ошибка чтения, напечатать disk_err_msg и остановиться
disk_error:
	mov si, disk_err_msg
	call print

; Остановить процессор
halt:
	cli
	hlt
	jmp halt

; Напечатать на экран
print:
	; Загрузка символа (по адресу SI)
	lodsb 
	
	; Если символ NULL (код 0), значит конец строки
	or al, al
	jz .done
	
	; Печать
	mov ah, 0x0E	; BIOS Teletype
	mov bh, 0x00 	; Страница 0
	mov bl, 0x07 	; Цвет
	int 0x10		; Вызов BIOS через прерывание 0x10
	jmp print		; Следующий символ
.done:
	ret

; Данные
boot_drive db 0
disk_err_msg db 'Disk read error', 0

times 510 - ($ - $$) db 0 ; Заполнить до 510 байт
dw 0xAA55 ; Ещё 2 байта -- сигнатура: 0x55, 0xAA (обязательно для некоторых BIOSов)