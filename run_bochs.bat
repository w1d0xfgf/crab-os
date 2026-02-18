cls

:: Stage 1 и 2 в сырые бинарники
nasm -f bin -o bin/stage1.bin src/boot/stage1.asm
nasm -f bin -o bin/stage2.bin src/boot/stage2.asm

:: Скомпилировать ядро
nasm -f elf32 -o obj/entry.o src/entry.asm
clang -target i386-pc -march=i486 -flto -m32 -g0 -I./src/c/headers/ -mgeneral-regs-only -Os -funified-lto -ffreestanding -mno-sse -mno-avx -mno-mmx -fno-stack-protector -fomit-frame-pointer -fno-pic -mno-red-zone -nostdlib -c -o obj/mouse.o src/c/mouse.c
clang -target i386-pc -march=i486 -flto -m32 -g0 -I./src/c/headers/ -mgeneral-regs-only -Os -funified-lto -ffreestanding -mno-sse -mno-avx -mno-mmx -fno-stack-protector -fomit-frame-pointer -fno-pic -mno-red-zone -nostdlib -c -o obj/speaker.o src/c/speaker.c
clang -target i386-pc -march=i486 -flto -m32 -g0 -I./src/c/headers/ -mgeneral-regs-only -Os -funified-lto -ffreestanding -mno-sse -mno-avx -mno-mmx -fno-stack-protector -fomit-frame-pointer -fno-pic -mno-red-zone -nostdlib -c -o obj/kbc.o src/c/kbc.c
clang -target i386-pc -march=i486 -flto -m32 -g0 -I./src/c/headers/ -mgeneral-regs-only -O3 -funified-lto -ffreestanding -mno-sse -mno-avx -mno-mmx -fno-stack-protector -fomit-frame-pointer -fno-pic -mno-red-zone -nostdlib -c -o obj/pmm.o src/c/pmm.c
clang -target i386-pc -march=i486 -flto -m32 -g0 -I./src/c/headers/ -mgeneral-regs-only -Os -funified-lto -ffreestanding -mno-sse -mno-avx -mno-mmx -fno-stack-protector -fomit-frame-pointer -fno-pic -mno-red-zone -nostdlib -c -o obj/utils.o src/c/utils.c
clang -target i386-pc -march=i486 -flto -m32 -g0 -I./src/c/headers/ -mgeneral-regs-only -O2 -funified-lto -ffreestanding -mno-sse -mno-avx -mno-mmx -fno-stack-protector -fomit-frame-pointer -fno-pic -mno-red-zone -nostdlib -c -o obj/keyboard.o src/c/keyboard.c
clang -target i386-pc -march=i486 -flto -m32 -g0 -I./src/c/headers/ -mgeneral-regs-only -Os -funified-lto -ffreestanding -mno-sse -mno-avx -mno-mmx -fno-stack-protector -fomit-frame-pointer -fno-pic -mno-red-zone -nostdlib -c -o obj/cmos.o src/c/cmos.c
clang -target i386-pc -march=i486 -flto -m32 -g0 -I./src/c/headers/ -mgeneral-regs-only -Os -funified-lto -ffreestanding -mno-sse -mno-avx -mno-mmx -fno-stack-protector -fomit-frame-pointer -fno-pic -mno-red-zone -nostdlib -c -o obj/print.o src/c/print.c
clang -target i386-pc -march=i486 -flto -m32 -g0 -I./src/c/headers/ -mgeneral-regs-only -O3 -funified-lto -ffreestanding -mno-sse -mno-avx -mno-mmx -fno-stack-protector -fomit-frame-pointer -fno-pic -mno-red-zone -nostdlib -c -o obj/pit.o src/c/pit.c
clang -target i386-pc -march=i486 -flto -m32 -g0 -I./src/c/headers/ -mgeneral-regs-only -Os -funified-lto -ffreestanding -mno-sse -mno-avx -mno-mmx -fno-stack-protector -fomit-frame-pointer -fno-pic -mno-red-zone -nostdlib -c -o obj/pic.o src/c/pic.c
clang -target i386-pc -march=i486 -flto -m32 -g0 -I./src/c/headers/ -mgeneral-regs-only -Os -funified-lto -ffreestanding -mno-sse -mno-avx -mno-mmx -fno-stack-protector -fomit-frame-pointer -fno-pic -mno-red-zone -nostdlib -c -o obj/idt.o src/c/idt.c
clang -target i386-pc -march=i486 -flto -m32 -g0 -I./src/c/headers/ -mgeneral-regs-only -O2 -funified-lto -ffreestanding -mno-sse -mno-avx -mno-mmx -fno-stack-protector -fomit-frame-pointer -fno-pic -mno-red-zone -nostdlib -c -o obj/vga.o src/c/vga.c
clang -target i386-pc -march=i486 -flto -m32 -g0 -I./src/c/headers/ -mgeneral-regs-only -Os -funified-lto -ffreestanding -mno-sse -mno-avx -mno-mmx -fno-stack-protector -fomit-frame-pointer -fno-pic -mno-red-zone -nostdlib -c -o obj/main.o src/c/main.c
ld.lld --lto-O2 --lto=full --no-gc-sections -m elf_i386 -T linker.ld -o kernel.elf obj/entry.o obj/main.o obj/vga.o obj/idt.o obj/pic.o obj/pit.o obj/print.o obj/cmos.o obj/keyboard.o obj/utils.o obj/pmm.o obj/kbc.o obj/speaker.o obj/mouse.o

:: В .bin
llvm-objcopy -O binary kernel.elf bin/kernel.bin

:: Сконвертировать всё в 1.44 МБ .img
copy /b bin\stage1.bin + bin\stage2.bin + bin\kernel.bin build.img
conv.exe build.img 1.44mb_build.img

:: Запустить в Bochs
bochs -f bochsrc.bxrc -q