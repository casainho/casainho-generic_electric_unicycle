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
LD      = $(TCPREFIX)ld -v
CP      = $(TCPREFIX)objcopy
OD      = $(TCPREFIX)objdump
GDB     = $(TCPREFIX)gdb

# -mfix-cortex-m3-ldrd should be enabled by default for Cortex M3.
# CFLAGS -H show header files
AFLAGS  = -Igeneric-electric-unicycle/firmware/src -Igeneric-electric-unicycle/firmware/src/spl/CMSIS -Igeneric-electric-unicycle/firmware/src/spl/inc -c -g -mcpu=cortex-m3 -mthumb
CFLAGS  = -Igeneric-electric-unicycle/firmware/src -Igeneric-electric-unicycle/firmware/src/spl/CMSIS -Igeneric-electric-unicycle/firmware/src/spl/CMSIS/inc -Igeneric-electric-unicycle/firmware/src/spl/inc -DSTM32F10X_MD -DUSE_STDPERIPH_DRIVER -c -fno-common -O0 -g -mcpu=cortex-m3 -mthumb
LFLAGS  = -Tgeneric-electric-unicycle/firmware/src/stm32_flash.ld -L/usr/lib/gcc/arm-none-eabi/4.9.3/armv7-m -lgcc -nostartfiles
CPFLAGS = -Obinary 
ODFLAGS = -S

SOURCES=$(shell find generic-electric-unicycle/firmware/src -type f -iname '*.c')
OBJECTS=$(foreach x, $(basename $(SOURCES)), $(x).o)


all: main.bin 


clean: 
	rm -f main.lst main.elf main.bin
	find -name *.o | xargs rm

flash: main.bin 
	$(STM32FLASH) generic-electric-unicycle/firmware/src/main.bin

main.bin: main.elf
	@echo "...copying"
	$(CP) $(CPFLAGS) generic-electric-unicycle/firmware/src/main.elf generic-electric-unicycle/firmware/src/main.bin
	$(OD) $(ODFLAGS) generic-electric-unicycle/firmware/src/main.elf> generic-electric-unicycle/firmware/src/main.lst

main.elf: $(OBJECTS) generic-electric-unicycle/firmware/src/startup_stm32f10x_md.o
	@echo "..linking"
	$(LD)  $^ $(LFLAGS) -o generic-electric-unicycle/firmware/src/$@

%.o: %.c
	@echo ".compiling"
	$(CC) $(CFLAGS) $< -o $@

startup_stm32f10x_md.o:
	$(AS) $(ASFLAGS) generic-electric-unicycle/firmware/src/startup_stm32f10x_md.s -o generic-electric-unicycle/firmware/src/startup_stm32f10x_md.o

