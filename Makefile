LFLAGS = -d --noyywrap --yylineno --nodefault 

YFLAGS = -t -k  --report-file=parser.out --verbose
YACC = bison

CPPFLAGS = -D_GNU_SOURCE
CFLAGS   = -std=c11 -fPIC -g -O0 -Wall

DESTDIR = /usr/local
PREFIX = $(DESTDIR)
SONAME = libanycsv.so.0

PWD ?= $(shell pwd)

all: $(SONAME) csv2any

csv2any: main.o csvany.h | $(SONAME)
	$(CC) -o $@ $< \
	-L$(PWD) -Wl,-rpath -Wl,$(PWD) \
	-L$(PREFIX)/lib -Wl,-rpath -Wl,$(PREFIX)/lib \
	-lanycsv

$(SONAME): parse.o scan.o
	$(CC) -o $@ -shared $(CPPFLAGS) $(CFLAGS) $^ -Wl,-soname,$(SONAME)

scan.o: scan.c
	$(CC) -c -o$@ $(CPPFLAGS) $(subst -Wall,,$(CFLAGS)) $^

parse.c: parse.y
	$(YACC) $(YFLAGS) -o$@ $^

SRC = $(wildcard *.[yl]) main.c parse.h
tags: TAGS
TAGS: $(SRC)
	etags $^

install: csv2any $(SONAME)
	mkdir -p $(PREFIX)/bin/ $(PREFIX)/share/man/man1/ \
		 $(PREFIX)/lib/ $(PREFIX)/share/man/man3/

	install         csv2any      $(PREFIX)/bin/
	install -m 0644 csv2any.1    $(PREFIX)/share/man/man1/
	install         $(SONAME)    $(PREFIX)/lib/
	install -m 0644 libanycsv.3  $(PREFIX)/share/man/man3/
	cd $(PREFIX)/lib && ln -s $(SONAME) $(subst .so.0,.so,$(SONAME))
