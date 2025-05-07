# hal - CNF-SAT solver

include config.mk

CSRC := src/main.c src/cnf.c src/solve.c src/parser.c
COBJ := $(CSRC:.c=.o)

CFLAGS := $(CFLAGS) $(ADDCFLAGS)

all: hal
hal: $(COBJ)
	$(LD) -o $@ $^

clean:
	rm -f hal
	rm -f hal-$(VERSION).tar.gz
	rm -f $(COBJ)

dist: clean
	mkdir -p hal-$(VERSION)
	cp -R COPYING Makefile README.markdown config.mk\
		INSTALL hal-$(VERSION)
	tar -cf hal-$(VERSION) | gzip > hal-$(VERSION).tar.gz
	rm -rf hal-$(VERSION)

INSTALL=install
INSTALL_PROGRAM=$(INSTALL)
BINDIR=$(DESTDIR)$(PREFIX)/bin

install: hal
	mkdir -p $(BINDIR)
	$(INSTALL_PROGRAM) hal $(BINDIR)
uninstall:
	rm -f $(BINDIR)/hal

.PHONY: all clean dist install uninstall
