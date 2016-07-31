#  Copyright (C) 2015 Joerg Hoener
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.


TCPREFIX  = arm-none-eabi-
CC      = $(TCPREFIX)gcc
AS      = $(TCPREFIX)as 
LD      = $(TCPREFIX)gcc -v # use GCC and not LD so the math functions work like atan2()
CP      = $(TCPREFIX)objcopy
OD      = $(TCPREFIX)objdump
GDB     = $(TCPREFIX)gdb
SIZE     = $(TCPREFIX)size

# Optimization level, can be [0, 1, 2, 3, s]. 
# 0 = Turn off optimization. Reduce compilation time and make debugging
#     produce the expected results.
# 1 = The compiler tries to reduce code size and execution time, without
#     performing any optimizations that take a great deal of compilation time.
# 2 = GCC performs nearly all supported optimizations that do not involve a 
#     space-speed tradeoff. As compared to -O1, this option increases
#     both compilation time and the performance of the generated code.
# 3 = Optimize yet more. Turns on -finline-functions and more.
# s = -Os enables all -O2 optimizations that do not typically increase code
#     size.
# (See gcc manual for further information)
OPT = 0

# -mfix-cortex-m3-ldrd should be enabled by default for Cortex M3.
# CFLAGS -H show header files
AFLAGS  = -Ifirmware-gen1_boards/src -Ifirmware-gen1_boards/src/spl/CMSIS -Ifirmware-gen1_boards/src/spl/inc -c -g -mcpu=cortex-m3 -mthumb
CFLAGS  = -Ifirmware-gen1_boards/src -Ifirmware-gen1_boards/src/spl/CMSIS -Ifirmware-gen1_boards/src/spl/CMSIS/inc -Ifirmware-gen1_boards/src/spl/inc -DSTM32F10X_MD -DUSE_STDPERIPH_DRIVER -c -fno-common -O$(OPT) -g -mcpu=cortex-m3 -mthumb
# Need following option for LTO as LTO will treat retarget functions as
# unused without following option
CFLAGS+=-fno-builtin
LFLAGS  = -Tfirmware-gen1_boards/src/stm32_flash.ld -L/usr/lib/gcc/arm-none-eabi/4.9.3/armv7-m -lgcc -lm -nostartfiles -lnosys -mcpu=cortex-m3 -mthumb
CPFLAGS = -Obinary 
ODFLAGS = -S

SOURCES=$(shell find firmware-gen1_boards/src -type f -iname '*.c')
OBJECTS=$(foreach x, $(basename $(SOURCES)), $(x).o)


all: main.bin size


clean: 
	rm -f main.lst main.elf main.bin
	find -name *.o | xargs rm

flash: main.bin 
	$(STM32FLASH) firmware-gen1_boards/src/main.bin

size:
	@echo "Size:"
	$(SIZE) firmware-gen1_boards/src/main.elf

main.bin: main.elf
	@echo "...copying"
	$(CP) $(CPFLAGS) firmware-gen1_boards/src/main.elf firmware-gen1_boards/src/main.bin
	$(OD) $(ODFLAGS) firmware-gen1_boards/src/main.elf> firmware-gen1_boards/src/main.lst

main.elf: $(OBJECTS) firmware-gen1_boards/src/startup_stm32f10x_md.o
	@echo "..linking"
	$(LD)  $^ $(LFLAGS) -o firmware-gen1_boards/src/$@

%.o: %.c
	@echo ".compiling"
	$(CC) $(CFLAGS) $< -o $@

startup_stm32f10x_md.o:
	$(AS) $(ASFLAGS) firmware-gen1_boards/src/startup_stm32f10x_md.s -o firmware-gen1_boards/src/startup_stm32f10x_md.o

