# name of the project, the binaries will be generated with this name
PROJ_NAME = HedgehogLLC


#compiler
export CC = arm-none-eabi-gcc
#linker
export LD = arm-none-eabi-gcc
#objcopy
export OC = arm-none-eabi-objcopy
#size
export SZ = arm-none-eabi-size

#linker flags
export LDFLAGS = -mcpu=cortex-m4 -DSTM32F401xC -mlittle-endian -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard -static -Wl,--gc-sections
#compiler flags
export CFLAGS = -mcpu=cortex-m4 -DSTM32F401xC -mlittle-endian -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard -fno-common -ffunction-sections -fdata-sections -Wall -Og -g -c

###################################################

#root directory containing the makefile and user source files
ROOTDIR := $(CURDIR)

#directory containing system files
SYSTEMDIR := system

#directory containing user sources
SRCDIR := src

#directory for binary output files
BUILDDIR := build

#directory for object files
OBJDIR := build/obj


#include directories
CFLAGS += -I$(SYSTEMDIR)

#linker file
LDFLAGS += -T$(SYSTEMDIR)/STM32F401XB_FLASH.ld

#libraries we want to link against
#LDFLAGS += -lc -lnosys #newlib (e.g. for printf)
LDFLAGS += -lm #math

#system source files
SRC = startup_stm32f401xc.s system.c

#user source files
SRC += main.c


#object files (with build dir --> $(OBJDIR)/name.o)
OBJS = $(addprefix $(OBJDIR)/,$(subst .c,.o,$(subst .s,.o,$(SRC))))

#source files (with source dir)
SOURCES = $(addprefix $(SRCDIR)/,$(SRC))

###################################################

.PHONY: all buildAll flash remote-flash flash-stlink size clean

#build and show size
all: buildAll size

#build all output formats
buildAll: $(BUILDDIR)/$(PROJ_NAME).elf $(BUILDDIR)/$(PROJ_NAME).hex $(BUILDDIR)/$(PROJ_NAME).bin
	@echo build finished

#flash using stm32flasher
flash:
	stm32flasher $(BUILDDIR)/$(PROJ_NAME).bin

#flashe remotely via orange pi in network
remote-flash:
	rsync -avz $(BUILDDIR)/$(PROJ_NAME).bin orangepi@10.42.0.226:/tmp/
	ssh orangepi@10.42.0.226 stm32flasher /tmp/$(PROJ_NAME).bin

#flash using github.com/texane/stlink
flash-stlink:
	st-flash --reset write $(BUILDDIR)/$(PROJ_NAME).bin 0x8000000
	@echo flash finished


#shows size of .elf
size: $(BUILDDIR)/$(PROJ_NAME).elf
	$(SZ) $<


#create .hex from .elf
$(BUILDDIR)/$(PROJ_NAME).hex: $(BUILDDIR)/$(PROJ_NAME).elf | $(BUILDDIR)
	@echo creating $@ from $<
	@$(OC) -Oihex $< $@

#create .bin from .elf
$(BUILDDIR)/$(PROJ_NAME).bin: $(BUILDDIR)/$(PROJ_NAME).elf | $(BUILDDIR)
	@echo creating $@ from $<
	@$(OC) -Obinary $< $@

#link objects to .elf
$(BUILDDIR)/$(PROJ_NAME).elf: $(OBJS) | $(OBJDIR) $(BUILDDIR)
	@echo linking $@ from $(OBJS)
	@$(LD) $(LDFLAGS) -o $@ $(OBJS)


#compile user .c file to .o
$(OBJDIR)/%.o: $(SRCDIR)/%.c | $(OBJDIR)
	@echo compiling $@ from $<
	@$(CC) $(CFLAGS) -o $@ $<

#compile system .c file to .o
$(OBJDIR)/%.o: $(SYSTEMDIR)/%.c | $(OBJDIR)
	@echo compiling $@ from $<
	@$(CC) $(CFLAGS) -o $@ $<

#compile system .s file to .o
$(OBJDIR)/%.o: $(SYSTEMDIR)/%.s | $(OBJDIR)
	@echo compiling $@ from $<
	@$(CC) $(CFLAGS) -o $@ $<


#create directory for objects
$(OBJDIR):
	mkdir -p $@

#create directory for output files
$(BUILDDIR):
	mkdir -p $@


#delete all build products
clean:
	rm -f $(OBJDIR)/*.o
	rm -f $(BUILDDIR)/$(PROJ_NAME).*
	@echo
