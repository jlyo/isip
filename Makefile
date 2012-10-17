RLSRC = isip.rl
CSRC = canonip.c

RAGEL ?= ragel
DOT ?= dot
INSTALL ?= install
DOTFLAGS ?=
RAGEL_FLAGS ?= -G2
CFLAGS += -Wall -Wextra -Wshadow -std=gnu99 -fPIC -g -pedantic -O2
PREFIX ?= /usr/local
LIBDIR ?= $(PREFIX)/lib
BINDIR ?= $(PREFIX)/bin

ifeq ($(CC),musl-gcc)
	LDFLAGS += -static
endif

TARGET = $(RLSRC:%.rl=%) $(CSRC:%.c=%)
OBJ    = $(RLSRC:%.rl=%.o) $(CSRC:%.c=%.o)
RLCSRC = $(RLSRC:%.rl=%.c)
RLPDF  = $(RLSRC:%.rl=%.pdf)
RLDOT  = $(RLSRC:%.rl=%.dot)

.PHONY: all
all: $(TARGET)

%.c: %.rl
	$(RAGEL) $(RAGEL_FLAGS) -o $@ $<
%.dot: %.rl
	$(RAGEL) $(RAGEL_FLAGS) -V -o $@ $<
%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<
%.pdf: %.dot
	$(DOT) $(DOTFLAGS) -Tpdf -o $@ $<
%: %.o
	$(CC) $(CFLAGS) -o $@ $(LDFLAGS) $<

.PHONY: check
check: check.sh isip
	./check.sh

.PHONY: install
install: $(TARGET)
	$(INSTALL) -dm755 $(DESTDIR)$(BINDIR)
	$(INSTALL) -m755 isip $(DESTDIR)$(BINDIR)

.PHONY: clean
clean:
	-rm -f $(TARGET) $(OBJ) $(RLCSRC) $(RLPDF) $(RLDOT)
