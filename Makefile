# Copyright (C) 2012 Jesse Young
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
# KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
# AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
# IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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
	$(INSTALL) -m755 canonip $(DESTDIR)$(BINDIR)

.PHONY: clean
clean:
	-rm -f $(TARGET) $(OBJ) $(RLCSRC) $(RLPDF) $(RLDOT)
