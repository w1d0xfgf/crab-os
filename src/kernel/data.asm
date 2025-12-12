; ------------------------------------------------------------------
; Данные
; ------------------------------------------------------------------

; VGA атрибут (цвет) печати на экран
vga_attr db 0x07

; Координаты в символах печати на экран
pos_x db 0
pos_y db 0

; Аргументы print_reg32, println_reg32, print_reg8 и println_reg8
reg32 dd 0
reg8 db 0

; panic
panic_msg:
		db '      PANIC!          ', 13, 10
		db '                      ', 13, 10
		db '      _~^~^~_         ', 13, 10
		db '  \) /  o o  \ (/     ', 13, 10
		db "    '_   ", 0x7F, "   _'       ", 13, 10
		db "    / '-----' \       ", 0

; Таблица для перевода Scancode (set 1) в ASCII
; таблица[сканкод] = ASCII символ
scancode_to_ascii:
    db 0
    db 0
    db '1'          ; 0x02
    db '2'          ; 0x03
    db '3'          ; 0x04
    db '4'          ; 0x05
    db '5'          ; 0x06
    db '6'          ; 0x07
    db '7'          ; 0x08
    db '8'          ; 0x09
    db '9'          ; 0x0A
    db '0'          ; 0x0B
    db '-'          ; 0x0C
    db '='          ; 0x0D
    db 0
    db 0

    db 'q'          ; 0x10
    db 'w'          ; 0x11
    db 'e'          ; 0x12
    db 'r'          ; 0x13
    db 't'          ; 0x14
    db 'y'          ; 0x15
    db 'u'          ; 0x16
    db 'i'          ; 0x17
    db 'o'          ; 0x18
    db 'p'          ; 0x19
    db '['          ; 0x1A
    db ']'          ; 0x1B
    db 0
    db 0
    db 'a'          ; 0x1E
    db 's'          ; 0x1F

    db 'd'          ; 0x20
    db 'f'          ; 0x21
    db 'g'          ; 0x22
    db 'h'          ; 0x23
    db 'j'          ; 0x24
    db 'k'          ; 0x25
    db 'l'          ; 0x26
    db ';'          ; 0x27
    db "'"          ; 0x28
    db '`'          ; 0x29
    db 0
    db '\'          ; 0x2B
    db 'z'          ; 0x2C
    db 'x'          ; 0x2D
    db 'c'          ; 0x2E
    db 'v'          ; 0x2F

    db 'b'          ; 0x30
    db 'n'          ; 0x31
    db 'm'          ; 0x32
    db ','          ; 0x33
    db '.'          ; 0x34
    db '/'          ; 0x35
    db 0
    db '*'          ; 0x37
    db 0
    db ' '          ; 0x39
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0

    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0

    db '7'          ; 0x47 KP7
    db '8'          ; 0x48 KP8
    db '9'          ; 0x49 KP9
    db '-'          ; 0x4A KP-
    db '4'          ; 0x4B KP4
    db '5'          ; 0x4C KP5
    db '6'          ; 0x4D KP6
    db '+'          ; 0x4E KP+
    db '1'          ; 0x4F KP1

    db '2'          ; 0x50 KP2
    db '3'          ; 0x51 KP3
    db '0'          ; 0x52 KP0
    db '.'          ; 0x53 KP.
    db 0
    db 0
    db 0
    db 0
    db 0
	times (0x80 - ($ - scancode_to_ascii)) db 0

; Таблица для перевода Scancode (set 1) в ASCII когда нажата клавиша Shift
; таблица[сканкод] = ASCII символ
scancode_to_ascii_shift:
    db 0
    db 0
    db '!'          ; 0x02
    db '@'          ; 0x03
    db '#'          ; 0x04
    db '$'          ; 0x05
    db '%'          ; 0x06
    db '^'          ; 0x07
    db '&'          ; 0x08
    db '*'          ; 0x09
    db '('          ; 0x0A
    db ')'          ; 0x0B
    db '_'          ; 0x0C
    db '+'          ; 0x0D
    db 0
    db 0

    db 'Q'          ; 0x10
    db 'W'          ; 0x11
    db 'E'          ; 0x12
    db 'R'          ; 0x13
    db 'T'          ; 0x14
    db 'Y'          ; 0x15
    db 'U'          ; 0x16
    db 'I'          ; 0x17
    db 'O'          ; 0x18
    db 'P'          ; 0x19
    db '{'          ; 0x1A
    db '}'          ; 0x1B
    db 0
    db 0
    db 'A'          ; 0x1E
    db 'S'          ; 0x1F

    db 'D'          ; 0x20
    db 'F'          ; 0x21
    db 'G'          ; 0x22
    db 'H'          ; 0x23
    db 'J'          ; 0x24
    db 'K'          ; 0x25
    db 'L'          ; 0x26
    db ':'          ; 0x27
    db '"'          ; 0x28
    db '~'          ; 0x29
    db 0
    db '|'          ; 0x2B
    db 'Z'          ; 0x2C
    db 'X'          ; 0x2D
    db 'C'          ; 0x2E
    db 'V'          ; 0x2F

    db 'B'          ; 0x30
    db 'N'          ; 0x31
    db 'M'          ; 0x32
    db '<'          ; 0x33
    db '>'          ; 0x34
    db '?'          ; 0x35
    db 0
    db '*'          ; 0x37
    db 0
    db ' '          ; 0x39
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0

    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0

    db '7'          ; 0x47 KP7
    db '8'          ; 0x48 KP8
    db '9'          ; 0x49 KP9
    db '-'          ; 0x4A KP-
    db '4'          ; 0x4B KP4
    db '5'          ; 0x4C KP5
    db '6'          ; 0x4D KP6
    db '+'          ; 0x4E KP+
    db '1'          ; 0x4F KP1

    db '2'          ; 0x50 KP2
    db '3'          ; 0x51 KP3
    db '0'          ; 0x52 KP0
    db '.'          ; 0x53 KP.
    db 0
    db 0
    db 0
    db 0
    db 0
    times (0x80 - ($ - scancode_to_ascii_shift)) db 0