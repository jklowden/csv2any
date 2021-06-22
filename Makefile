LFLAGS = -d --noyywrap --yylineno --nodefault 

YFLAGS = -t -k  --report-file=parser.out --verbose
YACC = bison

CPPFLAGS = -D_GNU_SOURCE
CFLAGS   = -std=c11 -fPIC -g -O0 -Wall

DESTDIR = /usr/local
PREFIX = $(DESTDIR)

PWD ?= $(shell pwd)

all: libanycsv.so csv2any

csv2any: main.o csvany.h| libanycsv.so
	$(CC) -o $@ $< \
	-L$(PWD) -Wl,-rpath -Wl,$(PWD) \
	-L$(PREFIX) -Wl,-rpath -Wl,$(PREFIX) \
	-lanycsv

libanycsv.so: parse.o scan.o
	$(CC) -o $@ -shared $(CPPFLAGS) $(CFLAGS) $^

scan.o: scan.c
	$(CC) -c -o$@ $(CPPFLAGS) $(subst -Wall,,$(CFLAGS)) $^

parse.c: parse.y
	$(YACC) $(YFLAGS) -o$@ $^

SRC = $(wildcard *.[yl]) main.c parse.h
tags: TAGS
TAGS: $(SRC)
	etags $^

install: csv2any libanycsv.so 
	install csv2any   $(PREFIX)/bin/
	install csv2any.1 $(PREFIX)/share/man/man1/
	install libanycsv.so $(PREFIX)/lib/
	install libanycsv.3  $(PREFIX)/share/man/man3/

