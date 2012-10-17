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

TARGET = isip
OBJ = isip.o

.PHONY: all
all: $(TARGET)

isip: isip.o
	$(CC) $(CFLAGS) -o $@ $(LDFLAGS) $<
%.c: %.rl
	$(RAGEL) $(RAGEL_FLAGS) -o $@ $<
%.dot: %.rl
	$(RAGEL) $(RAGEL_FLAGS) -V -o $@ $<
%.pdf: %.dot
	$(DOT) $(DOTFLAGS) -Tpdf -o $@ $<
%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

.PHONY: check
check: check.sh isip
	./check.sh

.PHONY: install
install: $(TARGET)
	$(INSTALL) -dm755 $(DESTDIR)$(BINDIR)
	$(INSTALL) -m755 isip $(DESTDIR)$(BINDIR)

.PHONY: clean
clean:
	-rm -f $(TARGET) $(OBJ)
