PREFIX ?= /usr/local
BINDIR := $(PREFIX)/bin

.PHONY: install uninstall test hooks

install:
	ln -sf "$(CURDIR)/pdfa4" "$(BINDIR)/pdfa4"

uninstall:
	rm -f "$(BINDIR)/pdfa4"

test:
	bats tests/pdfa4.bats

hooks:
	bash hooks/install.sh
