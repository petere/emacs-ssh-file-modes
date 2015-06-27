EMACS = emacs

SRCS = $(wildcard *.el)
OBJS = $(SRCS:%.el=%.elc)

VERSION = $(shell git describe)

all: $(OBJS)

dist: all
	mkdir -p dist/
	for file in $(SRCS); do sed -e '1,10s/^;; Version:.*$$/;; Version: $(VERSION)/' $$file >dist/$$file || exit; done

clean:
	$(RM) $(OBJS)
	$(RM) -r dist/

%.elc: %.el
	$(EMACS) -Q --batch -f batch-byte-compile $<

.PHONY: all clean dist
