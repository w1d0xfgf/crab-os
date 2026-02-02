cls

:: Stage 1 и 2 в сырые бинарники
nasm -f bin -o bin/stage1.bin src/boot/stage1.asm
nasm -f bin -o bin/stage2.bin src/boot/stage2.asm

:: Скомпилировать ядро
nasm -f elf32 src/drivers/vga.asm -o obj/vga.o
nasm -f elf32 src/drivers/pit.asm -o obj/pit.o
nasm -f elf32 src/drivers/keyboard.asm -o obj/keyboard.o
nasm -f elf32 src/drivers/mouse.asm -o obj/mouse.o
nasm -f elf32 src/drivers/rtc.asm -o obj/rtc.o
nasm -f elf32 src/drivers/speaker.asm -o obj/speaker.o
nasm -f elf32 src/drivers/floppy.asm -o obj/floppy.o
nasm -f elf32 src/functions/print.asm -o obj/print.o
nasm -f elf32 src/functions/rng.asm -o obj/rng.o
nasm -f elf32 src/functions/str.asm -o obj/str.o
nasm -f elf32 src/kernel/idt.asm -o obj/idt.o
nasm -f elf32 src/kernel/pmm.asm -o obj/pmm.o
nasm -f elf32 src/kernel/kernel.asm -o obj/kernel.o
nasm -f elf32 src/kernel/stack.asm -o obj/stack.o
nasm -f elf32 src/os/os.asm -o obj/os.o
nasm -f elf32 src/os/gui.asm -o obj/gui.o
nasm -f elf32 src/os/cmd.asm -o obj/cmd.o

:: Слинковать ядро в .bin
ld.lld -m elf_i386 -T linker.ld -nostdlib -n obj/kernel.o obj/vga.o obj/pit.o obj/keyboard.o obj/mouse.o obj/rtc.o obj/speaker.o obj/floppy.o obj/print.o obj/rng.o obj/str.o obj/idt.o obj/pmm.o obj/os.o obj/gui.o obj/cmd.o obj/stack.o -o kernel.elf
llvm-objcopy -O binary kernel.elf bin/kernel.bin

:: Сконвертировать всё в 1.44 МБ .img
copy /b bin\stage1.bin + bin\stage2.bin + bin\kernel.bin build.img
conv.exe build.img 1.44mb_build.img

:: Запустить в QEMU 
"C:\Program Files\qemu\qemu-system-i386.exe" -fda 1.44mb_build.img -display sdl