cls
nasm -f bin -o bin/boot.bin src/boot/boot.asm
nasm -f bin -o bin/main.bin src/kernel/kernel.asm
copy /b bin\boot.bin + bin\main.bin build.img
conv.exe build.img 1.44mb_build.img
"C:\Program Files\qemu\qemu-system-x86_64.exe" -fda 1.44mb_build.img