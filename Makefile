LFLAGS = -d --noyywrap --yylineno --nodefault 

YFLAGS = -t -k  --report-file=parser.out --verbose
YACC = bison

CPPFLAGS = -D_GNU_SOURCE
CFLAGS   = -fPIC -g -O0 -Wall

PREFIX = /usr/local

all: libcsv.so csv2any

csv2any: main.o
	$(CC) -o $@ $^ \
	-L$(PWD) -Wl,-rpath -Wl,$(PWD) \
	-L$(PREFIX) -Wl,-rpath -Wl,$(PREFIX) \
	-lcsv

libcsv.so: parse.o scan.o
	$(CC) -o $@ -shared $(CPPFLAGS) $(CFLAGS) $^

scan.o: scan.c
	$(CC) -c -o$@ $(CPPFLAGS) $(subst -Wall,,$(CFLAGS)) $^

parse.c: parse.y
	$(YACC) $(YFLAGS) -o$@ $^

tags: TAGS
TAGS:
	etags *.[yl] main.c parse.h

install: csv2any libcsv.so 
	install csv2any   $(PREFIX)/bin/
	install csv2any.1 $(PREFIX)/share/man/man1/
	install libcsv.so $(PREFIX)/lib/
	install libcsv.3  $(PREFIX)/share/man/man3/
