 #
# Simple Makefile to compile our bootloader
 #

BUILD		:=	build

GAS 		:=	as

LNK			:=	ld

GASFLAGS	=

OBJEXT		:=	.o

ASMEXT		:=	.S

LINKER		:=	bootloader/bootstrap.ld

RAWBIN		:=	bootstrap.bin

LNKFLAGS	:=	-n					\
				-T $(LINKER)		\
				-o $(RAWBIN)		\
				--oformat binary

SOURCE		:=	bootloader/boot/boot.S

OBJECT		:=	build/bootloader/boot/boot.o

all:	$(RAWBIN)

clean:
	@rm -rf	$(BUILD) $(RAWBIN)

run:	clean
	qemu-system-i386 -drive format=raw,file=$(RAWBIN)

$(RAWBIN):
	@mkdir -p $(shell dirname $(OBJECT))
	@$(GAS) $(GASFLAGS) -c $(SOURCE) -o $(OBJECT)
	@-echo "    AS    $@"
	@$(LNK) $(LNKFLAGS) $(OBJECT)
	@-echo "   LNK    $(RAWBIN)"