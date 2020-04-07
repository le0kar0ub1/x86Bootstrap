 #
# Simple Makefile to compile our bootloader
 #

BUILD		:=	build

GAS 		:=	as

LNK			:=	ld

GASFLAGS	=

OBJEXT		:=	.o

ASMEXT		:=	.S

LINKER		:=	bootloader/boostrap.ld

RAWBIN		:=	bootstrap.bin

LNKFLAGS	:=	-n					\
				-T $(LINKER)		\
				-o $(RAWBIN)		\
				--oformat binary

SRCDIR		:=	$(addprefix bootloader/, boot)

SOURCES		:=	$(wildcard $(addsuffix /*$(ASMEXT), $(SRCDIR)))

OBJECTS		:=	$(patsubst %$(ASMEXT), $(BUILD)/%$(OBJEXT), $(SOURCES))

all:	$(RAWBIN)

clean:
	@rm -rf	$(BUILD)

fclean:	clean
	@rm -f	$(RAWBIN)

run:	re
	qemu-system-i386 -drive format=raw,file=$(RAWBIN)

re:	fclean	all

$(RAWBIN):	$(OBJECTS)
	@$(LNK) $(LNKFLAGS) $(OBJECTS)
	@-echo "   LNK    $(RAWBIN)"

$(BUILD)/%$(OBJEXT): %$(ASMEXT)
	@mkdir -p $(shell dirname $@)
	@$(GAS) $(GASFLAGS) -c $< -o $@
	@-echo "    AS    $@"