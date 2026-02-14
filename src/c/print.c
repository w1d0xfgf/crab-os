#include "vga.h"
#include "print.h"

// Таблица для конвертации числа в шестнадцатеричную цифру
static u8 hex[] = "0123456789ABCDEF";

// Напечатать 32 битное число в десятичном формате
void print_decimal(console_t* con, u32 val) {
	u32 i = 0;
	volatile u8 str[11];

	while (val > 0) {
		// Получить первую (левую) цифру в числе (x mod 10) и сконвертировать в символ
		str[i++] = val % 10 + '0';

		// Следующая цифра
		val /= 10;
	}

	// Если цикл сделал хотя бы одну итерацию (есть хотя бы один символ)
	if (i) {
		// Строка слева направо (самая первая цифра самый последний символ)
		for (u32 j = 0, k = i - 1; j < k; j++, k--) {
			u8 temp = str[j];
			str[j] = str[k];
			str[k] = temp;
		}

		// NUL-терминация
		str[i] = 0;
	} else {
		// Ноль
		str[0] = '0';

		// NUL-терминация
		str[1] = 0;
	}

	// Напечатать
	vga_print(con, str);
}

// Напечатать 32 битное число в шестанцатеричном формате
void print_hex(console_t* con, u32 val) {
	volatile u8 str[9];

	// Пройтись по 8 цифрам
	for (int i = 7; i >= 0; i--) {
		// Получить первую (левую) цифру в числе и сконвертировать в символ
		// x mod 16 = x & 16
		str[i] = hex[val & 0xF];

		// Следующая цифра
		// x / y = x >> log2(y)
		val >>= 4;
	}

	// NUL-терминация
	str[8] = 0;

	vga_print(con, str);
}

// Напечатать 8 битное число в шестанцатеричном формате
void print_hex_8(console_t* con, u8 val) {
	volatile u8 str[3];

	// Пройтись по 2 цифрам
	for (int i = 1; i >= 0; i--) {
		// Получить первую (левую) цифру в числе и сконвертировать в символ
		// x mod 16 = x & 16
		str[i] = hex[val & 0xF];

		// Следующая цифра
		// x / y = x >> log2(y)
		val >>= 4;
	}

	// NUL-терминация
	str[2] = 0;

	vga_print(con, str);
}

// Напечатать строку с форматированием
void printf(console_t* con, const char* fmt, ...) {
	__builtin_va_list args;
	__builtin_va_start(args, fmt);

	// Пройтись по символам
	while (*fmt) {
		// Если символ '%'
		if (*fmt == '%') {
			// Следующий символ
			fmt++;

			// d/h/s/c
			switch (*fmt) {
				case 'd': {
					// Напечатать число в десятеричном формате
					i32 val = __builtin_va_arg(args, i32);
					print_decimal(con, val);
					break;
				}

				case 'h': {
					// Напечатать число в шестнадцатеричном формате
					i32 hex = __builtin_va_arg(args, i32);
					print_hex(con, hex);
					break;
				}

				case 'b': {
					// Напечатать 8 битное число в шестнадцатеричном формате
					i8 hex = __builtin_va_arg(args, i8);
					print_hex_8(con, hex);
					break;
				}

				case 's': {
					// Напечатать строку
					const char* str = __builtin_va_arg(args, const char*);
					vga_print(con, str);
					break;
				}

				case 'c': {
					// Напечатать символ
					char c = (char)__builtin_va_arg(args, i32);
					vga_putc(con, c);
					break;
				}

				default:
					break;
			}
		} else {
			// Напечатать символ как обычно
			vga_putc(con, *fmt);
		}
		fmt++;
	}

	__builtin_va_end(args);
}